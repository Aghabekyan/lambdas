#!/bin/bash
set -e

# project root
ROOT_DIR=$(pwd)
DIST_DIR="$ROOT_DIR/dist"

# make sure dist folder exists inside the project
mkdir -p "$DIST_DIR"

for service in services/*; do
  SERVICE_NAME=$(basename "$service")
  BUILD_DIR="/tmp/$SERVICE_NAME"

  echo "🔨 Building $SERVICE_NAME"

  # recreate temp build folder
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"

  # install dependencies
  if [ -f "$service/requirements.txt" ]; then
    pip install -r "$service/requirements.txt" -t "$BUILD_DIR"
  fi

  # copy lambda code
  cp "$service/lambda_function.py" "$BUILD_DIR/"

  # copy shared utils
  cp -r utils "$BUILD_DIR/"

  # zip into dist folder inside project
  cd "$BUILD_DIR"
  zip -r "$DIST_DIR/$SERVICE_NAME.zip" .
  cd "$ROOT_DIR"
done

echo "✅ All lambdas built in $DIST_DIR"
