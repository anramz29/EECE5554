#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"


read -p "Enter bag name: " BAG_NAME

if [ -z "$BAG_NAME" ]; then
    echo "No name provided. Exiting."
    exit 1
fi

OUTPUT_PATH="$DATA_DIR/$BAG_NAME"

if [ -d "$OUTPUT_PATH" ]; then
    read -p "Bag '$BAG_NAME' already exists. Overwrite? (y/N): " CONFIRM
    if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
        echo "Aborted."
        exit 1
    fi
    rm -rf "$OUTPUT_PATH"
fi

echo "Recording to: $OUTPUT_PATH"
echo "Press Ctrl+C to stop recording."
echo ""

ros2 bag record -o "$OUTPUT_PATH" /imu /gps
