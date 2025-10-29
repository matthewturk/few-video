#!/bin/bash

# I got this from Gemini.  I'm sorry.

# Define the file containing your download references
REFERENCE_FILE="data_sources.txt"
ROOT_DATA_DIR="data"

# Check if the reference file exists
if [ ! -f "$REFERENCE_FILE" ]; then
    echo "Error: Reference file '$REFERENCE_FILE' not found."
    exit 1
fi

echo "--- Starting data download and verification ---"

# Read the file line by line with the order: CATEGORY, CHECKSUM, URL
while IFS=' ' read -r CATEGORY EXPECTED_SHA256 TARGET_URL; do
    # Skip empty lines and lines starting with '#' (comments)
    if [[ -z "$CATEGORY" || "$CATEGORY" =~ ^# ]]; then
        continue
    fi
    
    # --- Determine File Paths ---
    ORIGINAL_FILENAME="${TARGET_URL##*/}"
    
    if [[ -z "$ORIGINAL_FILENAME" ]]; then
        echo "Warning: Skipped entry with malformed URL: $TARGET_URL"
        continue
    fi
    
    TARGET_DIR="$ROOT_DATA_DIR/$CATEGORY"
    OUTPUT_FILE="$TARGET_DIR/$ORIGINAL_FILENAME"
    
    echo "--------------------------------------------------------"
    echo "Processing: $ORIGINAL_FILENAME (Category: $CATEGORY)"
    
    # 🌟 NEW CHECK: Skip if the file already exists
    if [ -f "$OUTPUT_FILE" ]; then
        echo "** SKIP **: File already exists at $OUTPUT_FILE. Skipping download."
        continue
    fi

    # 3. Create the directory structure (e.g., 'data/raw-data') if it doesn't exist
    mkdir -p "$TARGET_DIR"

    # --- Download and Verification Step ---
    # This block is only reached if the file does NOT exist.
    
    echo "Source URL: $TARGET_URL"
    
    # curl downloads and tee pipes the stream to the file AND to sha256sum for checking.
    curl -s -L "$TARGET_URL" | tee "$OUTPUT_FILE" | sha256sum -c <(echo "$EXPECTED_SHA256  -")
    
    if [ $? -eq 0 ]; then
        echo "** SUCCESS **: $ORIGINAL_FILENAME checksum is valid."
    else
        echo "** FAILED! **: $ORIGINAL_FILENAME checksum does NOT match. Deleting file: $OUTPUT_FILE"
        rm -f "$OUTPUT_FILE"
    fi
    
done < "$REFERENCE_FILE"

echo "--- All checks and operations complete. ---"
