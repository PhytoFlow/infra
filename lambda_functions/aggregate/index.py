import json
import os
import zoneinfo
from datetime import datetime, timedelta, timezone
from io import BytesIO

import boto3
import pandas as pd

s3 = boto3.client("s3")


def handler(event, context):
    source_bucket = os.environ["SOURCE_BUCKET"]
    source_prefix = os.environ["SOURCE_PREFIX"]
    dest_bucket = os.environ["DEST_BUCKET"]
    dest_prefix = os.environ["DEST_PREFIX"]
    interval_minutes = int(os.environ["INTERVAL_MINUTES"])
    end_time = datetime.now(timezone.utc)
    start_time = end_time - timedelta(minutes=interval_minutes)
    raw_files = list_s3_files(source_bucket, source_prefix, from_date=start_time)
    if not raw_files:
        return {"status": "no_files"}
    aggregated_data = process_and_aggregate_data(raw_files, source_bucket, start_time, end_time)
    if aggregated_data.empty:
        return {"status": "no_data"}
    save_to_parquet(aggregated_data, dest_bucket, dest_prefix)
    return {"status": "success", "processed_files": len(raw_files)}


def list_s3_files(bucket: str, prefix: str, from_date: datetime):
    """Retrieve S3 file keys filtered by date."""
    response = s3.list_objects_v2(Bucket=bucket, Prefix=prefix)
    return [
        item["Key"]
        for item in response.get("Contents", [])
        if item["Key"].endswith(".json") and item["LastModified"] >= from_date
    ]


def process_and_aggregate_data(files, bucket, start_time, end_time):
    """Process JSON files from S3 and aggregate their data."""
    all_data = []
    for file_key in files:
        data = fetch_and_parse_json(bucket, file_key)
        if data is not None:
            all_data.append(data)
    if not all_data:
        return pd.DataFrame()
    combined_data = pd.concat(all_data, ignore_index=True)
    return aggregate_data(combined_data)


def fetch_and_parse_json(bucket: str, file_key: dict):
    """Fetch and parse a JSON file from S3 into a Pandas DataFrame."""
    try:
        response = s3.get_object(Bucket=bucket, Key=file_key)
        file_content = response["Body"].read()
        data = json.loads(file_content)
        timestamp = data["ingestion_timestamp"]
        normalized_data = pd.json_normalize(data["$unknown"])
        df = pd.DataFrame(normalized_data)
        df.columns = df.columns.str.replace(r".*\.", "", regex=True)
        df["ingestion_timestamp"] = timestamp
        return df
    except Exception as e:
        return {"status": "no_data"}


def aggregate_data(df):
    """Aggregate IoT data by timestamp and hourly time windows."""
    try:
        agg = (
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
        return agg
    except:
        return pd.DataFrame()


def save_to_parquet(dataframe, bucket, prefix):
    """Save a DataFrame as a Parquet file to S3."""
    if dataframe.empty:
        return None
    buffer = BytesIO()
    dataframe.to_parquet(buffer, engine="pyarrow", index=False)
    buffer.seek(0)
    # Horário de Brasília
    current_time = datetime.now(tz=zoneinfo.ZoneInfo(key="America/Sao_Paulo"))
    s3_key = f"{prefix}/{current_time.strftime('%Y-%m/%d/')}{int(current_time.timestamp())}.parquet"
    s3.put_object(Bucket=bucket, Key=s3_key, Body=buffer.getvalue())
