#!/bin/bash

# upload_static_assets.sh
# This script detects updated or new static files and uploads them to S3 automatically during deployment.

set -e  

# Define environment type: prod, beta, or local
ENV=$1

# Define S3 buckets based on environment
declare -A BUCKETS
BUCKETS=(
  [prod]="s3-static-test-upload"
  [beta]="s3-static-test-upload"
)

# --- VALIDATION ---

if [ -z "$ENV" ]; then
  echo "❗ Environment not specified. Usage: ./upload_static_assets.sh [prod|beta|local]"
  exit 1
fi

if [ "$ENV" == "local" ]; then
  echo "ℹ️ LOCAL environment detected. No upload to S3 necessary. Exiting."
  exit 0
fi

BUCKET=${BUCKETS[$ENV]}

if [ -z "$BUCKET" ]; then
  echo "❗ Invalid environment specified. Use 'prod' or 'beta'."
  exit 1
fi

# --- DETECT CHANGED FILES ---

# Detect newly added or modified files under 'static/' directory in the latest commit
echo "🔍 Detecting changes in static files..."
CHANGED_FILES=$(git diff --name-only $(git rev-list --max-parents=0 HEAD) HEAD | grep "^static/" || true)

if [ -z "$CHANGED_FILES" ]; then
  echo "✅ No changes detected in static files. Nothing to upload."
  exit 0
fi

# --- UPLOAD FILES TO S3 ---

echo "🚀 Uploading changed static files to S3 bucket: $BUCKET"

for file in $CHANGED_FILES; do
  if [ -f "$file" ]; then
    echo "Uploading $file..."
    aws s3 cp "$file" "s3://$BUCKET/$file" --acl public-read
  else
    echo "⚠️ File $file does not exist locally, skipping."
  fi
done

echo "🎉 All changed static files uploaded successfully to $BUCKET."

