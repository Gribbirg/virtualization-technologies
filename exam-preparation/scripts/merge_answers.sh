#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
BASE_DIR="$SCRIPT_DIR/.."
ANSWERS_DIR="$BASE_DIR/answers"
OUTPUT_FILE="$BASE_DIR/answers.md"

rm -f "$OUTPUT_FILE"

for file in $(ls -1 "$ANSWERS_DIR"/*.md | sort); do
    cat "$file" >> "$OUTPUT_FILE"
    echo -e "\n\n---\n" >> "$OUTPUT_FILE"
done

echo "Merged $(ls -1 "$ANSWERS_DIR"/*.md | wc -l | tr -d ' ') files into $OUTPUT_FILE"
