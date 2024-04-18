#!/usr/bin/env bash

# Expects paths for the destination and source directories.
# Example usage: ./make_mdx.sh /Users/potter/dest ./src

if [ $# -ne 2 ]; then
    echo "Error: Two paths (destination and source) are required."
    echo "Usage: $0 <destination_directory> <source_directory>"
    exit 1
fi

# Convert relative paths to absolute paths and ensure they are valid
DEST_TARGET_DIR=$(realpath --relative-to=. "$1" 2>/dev/null || echo "$1")
SRC_TARGET_DIR=$(realpath --relative-to=. "$2" 2>/dev/null || echo "$2")

# Create the directories if they do not exist
mkdir -p "${DEST_TARGET_DIR}"
mkdir -p "${SRC_TARGET_DIR}"

# Normalize the paths to absolute paths again after creation
DEST_TARGET_DIR=$(realpath "$DEST_TARGET_DIR")
SRC_TARGET_DIR=$(realpath "$SRC_TARGET_DIR")

# Ensure directories end with a slash
[[ "${DEST_TARGET_DIR}" != */ ]] && DEST_TARGET_DIR="${DEST_TARGET_DIR}/"
[[ "${SRC_TARGET_DIR}" != */ ]] && SRC_TARGET_DIR="${SRC_TARGET_DIR}/"

echo "Working with DEST_TARGET_DIR=${DEST_TARGET_DIR}"
echo "Working with SRC_TARGET_DIR=${SRC_TARGET_DIR}"

# Create a temporary directory for work
WORK_DIR=$(mktemp -d)

# Repository and path configurations
REPO_URL="https://github.com/Unstructured-IO/unstructured"
DEST_PYTHON_PATH="docs/source/ingest/destination_connectors/code/python/"
DEST_SHELL_PATH="docs/source/ingest/destination_connectors/code/bash/"
SRC_PYTHON_PATH="docs/source/ingest/source_connectors/code/python/"
SRC_SHELL_PATH="docs/source/ingest/source_connectors/code/bash/"

# Clone only the necessary directories using sparse-checkout
git clone --depth 1 --filter=blob:none --sparse "${REPO_URL}" "${WORK_DIR}"
cd "${WORK_DIR}" || exit
git sparse-checkout set "${DEST_PYTHON_PATH}" "${DEST_SHELL_PATH}" "${SRC_PYTHON_PATH}" "${SRC_SHELL_PATH}"

# Copy files to destination and source directories
cp -R "${WORK_DIR}/${DEST_PYTHON_PATH}"* "${DEST_TARGET_DIR}"
cp -R "${WORK_DIR}/${DEST_SHELL_PATH}"* "${DEST_TARGET_DIR}"
cp -R "${WORK_DIR}/${SRC_PYTHON_PATH}"* "${SRC_TARGET_DIR}"
cp -R "${WORK_DIR}/${SRC_SHELL_PATH}"* "${SRC_TARGET_DIR}"

# Function to convert code files to markdown
function convert_to_mdx() {
    local CODE_DIR="$1"
    cd "${CODE_DIR}" || exit
    echo "Converting files in ${CODE_DIR}"
    for f in *.py *.sh; do
        if [ -f "$f" ]; then
            local extension="${f##*.}"
            local lang=""
            if [ "$extension" = "py" ]; then
                lang="python"
            elif [ "$extension" = "sh" ]; then
                lang="bash"
            fi
            awk -v lang="$lang" 'BEGIN {print "```" lang}
                {print}
                END {print "```"}' "$f" > "${f}.mdx"
            mv "${f}.mdx" "$f"
        else
            echo "No files to convert in ${CODE_DIR}"
        fi
    done
}

convert_to_mdx "${DEST_TARGET_DIR}"
convert_to_mdx "${SRC_TARGET_DIR}"

# Clean up the work directory
rm -rf "${WORK_DIR}"
echo "Markdown files created in ${DEST_TARGET_DIR} and ${SRC_TARGET_DIR}"
