#!/bin/bash
set -e

ROOT_DIR=$(pwd)
DIST_DIR="$ROOT_DIR/dist"

for zipfile in "$DIST_DIR"/*.zip; do
  SERVICE_NAME=$(basename "$zipfile" .zip)
  FUNCTION_NAME="playground-service-$SERVICE_NAME"

  echo "🚀 Deploying $FUNCTION_NAME"

  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$zipfile" \
    --region us-east-1 \
    --profile playground \
    > /dev/null
done

echo "✅ All lambdas deployed to playground-service-*"
