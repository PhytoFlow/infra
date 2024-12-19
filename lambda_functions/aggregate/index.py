import json
import logging
import os
import zoneinfo
from datetime import datetime, timedelta, timezone
from io import BytesIO

import boto3
import pandas as pd

# Initialize S3 client
s3 = boto3.client("s3")

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def handler(event, context):
    source_bucket = os.environ["SOURCE_BUCKET"]
    source_prefix = os.environ["SOURCE_PREFIX"]
    dest_bucket = os.environ["DEST_BUCKET"]
    dest_prefix = os.environ["DEST_PREFIX"]
    interval_minutes = int(os.environ["INTERVAL_MINUTES"])

    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(minutes=interval_minutes)

    logger.info(f"Processing files from {start_time} to {end_time}.")
    raw_files = list_s3_files(source_bucket, source_prefix, from_date=start_time)

    if not raw_files:
        logger.info("No files found in the specified time range.")
        return {"status": "no_files"}

    aggregated_data = process_and_aggregate_data(raw_files, source_bucket, start_time, end_time)
    if aggregated_data.empty:
        logger.info("No valid data found in the processed files.")
        return {"status": "no_data"}

    save_to_parquet(aggregated_data, dest_bucket, dest_prefix)
    logger.info(f"Successfully processed {len(raw_files)} files.")
    return {"status": "success", "processed_files": len(raw_files)}


def list_s3_files(bucket: str, prefix: str, from_date: datetime):
    """Retrieve S3 file keys filtered by date."""
    try:
        response = s3.list_objects_v2(Bucket=bucket, StartAfter=prefix)
        logger.info(response)
        logger.info(s3.list_objects_v2(Bucket=bucket))
        if "Contents" not in response:
            logger.warning(f"No files found in bucket '{bucket}' with prefix '{prefix}'.")
            return []
        return [
            item["Key"]
            for item in response["Contents"]
            if item["Key"].endswith(".json") and item["LastModified"] >= from_date
        ]
    except Exception as e:
        logger.error(f"Error listing files in bucket '{bucket}': {e}")
        return []


def process_and_aggregate_data(files, bucket, start_time, end_time):
    """Process JSON files from S3 and aggregate their data."""
    all_data = []
    for file_key in files:
        data = fetch_and_parse_json(bucket, file_key)
        if data is not None:
            all_data.append(data)
        else:
            logger.warning(f"Skipped file: {file_key}. Invalid format or missing data.")

    if not all_data:
        return pd.DataFrame()

    combined_data = pd.concat(all_data, ignore_index=True)
    return aggregate_data(combined_data)


def fetch_and_parse_json(bucket: str, file_key: str):
    """Fetch and parse a JSON file from S3 into a Pandas DataFrame."""
    try:
        response = s3.get_object(Bucket=bucket, Key=file_key)
        file_content = response["Body"].read()
        data = json.loads(file_content)

        if "ingestion_timestamp" not in data or "$unknown" not in data:
            logger.error(f"File '{file_key}' does not match the expected schema.")
            return None

        timestamp = data["ingestion_timestamp"]
        normalized_data = pd.json_normalize(data["$unknown"])
        df = pd.DataFrame(normalized_data)
        df.columns = df.columns.str.replace(r".*\.", "", regex=True)
        df["ingestion_timestamp"] = timestamp
        return df

    except json.JSONDecodeError as e:
        logger.error(f"Error decoding JSON in file '{file_key}': {e}")
    except Exception as e:
        logger.error(f"Error processing file '{file_key}': {e}")
    return None


def aggregate_data(df):
    """Aggregate IoT data by timestamp and hourly time windows."""
    try:
        return (
            df.groupby("identifier")
            .agg(
                nodes_count=("identifier", "count"),
                temperature_mean=("temperature", "mean"),
                humidity_mean=("humidity", "mean"),
                soil_humidity_mean=("soil_humidity", "mean"),
                uv_intensity_mean=("uv_intensity", "mean"),
                soil_temperature_mean=("soil_temperature", "mean"),
                ingestion_timestamp_mean=("ingestion_timestamp", "mean"),
            )
            .reset_index()
        )
    except Exception as e:
        logger.error(f"Error aggregating data: {e}")
        return pd.DataFrame()


def save_to_parquet(dataframe, bucket, prefix):
    """Save a DataFrame as a Parquet file to S3."""
    if dataframe.empty:
        logger.warning("No data to save. Skipping Parquet upload.")
        return

    try:
        buffer = BytesIO()
        dataframe.to_parquet(buffer, engine="pyarrow", index=False)
        buffer.seek(0)

        current_time = datetime.now(tz=zoneinfo.ZoneInfo(key="America/Sao_Paulo"))
        s3_key = f"{prefix}/{current_time.strftime('%Y-%m/%d/')}{int(current_time.timestamp())}.parquet"
        s3.put_object(Bucket=bucket, Key=s3_key, Body=buffer.getvalue())
        logger.info(f"Data saved to S3 at '{s3_key}'.")

    except Exception as e:
        logger.error(f"Error saving data to Parquet in bucket '{bucket}': {e}")
