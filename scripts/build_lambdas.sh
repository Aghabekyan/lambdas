#!/bin/bash
set -e

# project root
ROOT_DIR=$(pwd)
DIST_DIR="$ROOT_DIR/dist"
CHECKSUM_FILE="$DIST_DIR/.lambda_checksums"

# make sure dist folder exists
mkdir -p "$DIST_DIR"

# load previous checksums if exists
declare -A OLD_CHECKSUMS
if [ -f "$CHECKSUM_FILE" ]; then
    while IFS=" " read -r lambda checksum; do
        OLD_CHECKSUMS["$lambda"]="$checksum"
    done < "$CHECKSUM_FILE"
fi

# will store new checksums
declare -A NEW_CHECKSUMS

for service in services/*; do
  SERVICE_NAME=$(basename "$service")
  BUILD_DIR="/tmp/$SERVICE_NAME"

  # compute checksum of lambda files + requirements
  CHECKSUM=$(find "$service" utils -type f -exec sha256sum {} \; | sort | sha256sum | awk '{print $1}')
  NEW_CHECKSUMS["$SERVICE_NAME"]="$CHECKSUM"

  # check if checksum changed
  if [ "${OLD_CHECKSUMS[$SERVICE_NAME]}" == "$CHECKSUM" ]; then
      echo "⏩ Skipping $SERVICE_NAME (no changes)"
      continue
  fi

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

# save new checksums
> "$CHECKSUM_FILE"
for lambda in "${!NEW_CHECKSUMS[@]}"; do
    echo "$lambda ${NEW_CHECKSUMS[$lambda]}" >> "$CHECKSUM_FILE"
done

echo "✅ All changed Lambdas built in $DIST_DIR"
