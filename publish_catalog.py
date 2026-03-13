# scripts/publish_catalog.py
import boto3
import os
from dotenv import load_dotenv

load_dotenv()

s3 = boto3.client(
    's3',
    endpoint_url=os.getenv('S3_ENDPOINT'),
    aws_access_key_id=os.getenv('S3_ACCESS_KEY'),
    aws_secret_access_key=os.getenv('S3_SECRET_KEY'),
)

s3.upload_file(
    'catalog.json',
    os.getenv('S3_BUCKET'),
    'stac-data/catalog.json',
    ExtraArgs={'ContentType': 'application/json'}
)

print("✓ catalog.json publié sur S3") 
