#!/usr/bin/env bash
set -euo pipefail

# Define the minecraft mods folder
MODS_DIR="${HOME}/.local/share/PrismLauncher/instances/Alana/.minecraft/mods"

# Define output CSV file
OUTPUT_FILE="output.csv"

# Define tags to extract from fabric.mod.json
TAGS=("name" "version" "description")

# Capitalize first letter of each tag for CSV header
CAPITALIZED_TAGS=("${TAGS[@]^}")

# Generate header for CSV
IFS=','
echo "${CAPITALIZED_TAGS[*]}" >"$OUTPUT_FILE"

# Loop through mod file in directory
for mod in "$MODS_DIR"/*.jar; do
    # Create temporary dir for extracting files
    TEMP_DIR=$(mktemp -d)

    # Extract fabric.mod.json from jar file to temp dir
    unzip -qq "$mod" "fabric.mod.json" -d "$TEMP_DIR"

    # Check if fabric.mod.json was extracted
    JSON_FILE="$TEMP_DIR/fabric.mod.json"
    if [[ -f "$JSON_FILE" ]]; then
        # Clean JSON file by removing control characters
        CLEAN_JSON=$(tr <"$JSON_FILE" -d '\000-\031' | tr -d '\r')

        # Check if JSON is valid
        if echo "$CLEAN_JSON" | jq empty >/dev/null 2>&1; then
            # Use jq to extract values from specified tags
            VALUES=()
            for TAG in "${TAGS[@]}"; do
                # Extract the value using jq, handle missing tags gracefully
                VALUE=$(echo "$CLEAN_JSON" | jq -r --arg tag "$TAG" '.[$tag] // "N/A"')
                # Escape double quotes in values and wrap in quotes for CSV
                ESCAPED_VALUE=$(echo "$VALUE" | sed 's/"/""/g') # Escape internal quotes
                VALUES+=("\"$ESCAPED_VALUE\"")                  # Add quotes around the value
            done

            # Join values with commas and append to CSV
            IFS=','
            echo "${VALUES[*]}" >>"$OUTPUT_FILE"
        else
            echo "Warning: invalid JSON in $mod"
        fi
    else
        echo "Warning: fabric.mod.json not found in $mod"
    fi

    # Clean up
    rm -rf "$TEMP_DIR"
done

echo "Data extraction complete. Check the file: $OUTPUT_FILE"
