#!/bin/bash

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --profile academy --query Account --output text)
REPOSITORY_NAME="iot-data-aggregation-lambda"
IMAGE_TAG="latest"

# Login to ECR
aws ecr get-login-password --profile academy --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build the Docker image
docker build -t $REPOSITORY_NAME:$IMAGE_TAG .

# Tag the Docker image
docker tag $REPOSITORY_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG

# Push the Docker image to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:$IMAGE_TAG