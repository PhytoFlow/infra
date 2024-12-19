resource "aws_glue_catalog_database" "iot_data_db" {
  name = "iot_data_catalog"
}

resource "aws_glue_crawler" "iot_data_crawler" {
  database_name = aws_glue_catalog_database.iot_data_db.name
  name          = "iot-data-crawler"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"

  s3_target {
    path = "s3://${aws_s3_bucket.iot_data.id}/raw"
  }

  configuration = jsonencode({
    Version = 1.0
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })

  schema_change_policy {
    delete_behavior = "LOG"
  }
}

resource "aws_ecr_repository" "lambda_ecr_repo" {
  name = "iot-data-aggregation-lambda"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "iot-data-aggregation-lambda-repo"
    Environment = var.environment
  }
}

resource "aws_lambda_function" "iot_data_aggregation" {
  function_name = "iot-data-aggregation"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  image_uri     = "${aws_ecr_repository.lambda_ecr_repo.repository_url}:latest"
  package_type  = "Image"
  timeout = 300

  environment {
    variables = {
      SOURCE_BUCKET    = aws_s3_bucket.iot_data.id
      SOURCE_PREFIX    = "raw/irrigation/sensors"
      DEST_BUCKET      = aws_s3_bucket.iot_data.id
      DEST_PREFIX      = "aggregated"
      INTERVAL_MINUTES = "30"
      GLUE_DATABASE    = aws_glue_catalog_database.iot_data_db.name
    }
  }
}


resource "aws_cloudwatch_event_rule" "lambda_trigger" {
  name                = "iot-data-aggregation-trigger"
  description         = "Trigger IoT data aggregation Lambda every 30 minutes"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_trigger_target" {
  rule      = aws_cloudwatch_event_rule.lambda_trigger.name
  target_id = "TriggerAggregationLambda"
  arn       = aws_lambda_function.iot_data_aggregation.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot_data_aggregation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_trigger.arn
}
