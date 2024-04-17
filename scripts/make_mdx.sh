#!/usr/bin/env bash

# This script downloads the .py and .sh code from the open source repo
# Then it converts the code to markdown files

# Requres two ABSOLUTE paths to the final destination and source directories
# ex: ./make_mdx.sh /Users/potter/dest /Users/potter/src

# make temp directory
WORK_DIR=$(mktemp -d) 

PY_DEST_REPO="docs/source/ingest/destination_connectors/code/python/"
SH_DEST_REPO="docs/source/ingest/destination_connectors/code/bash/"
DEST_TARGET_DIR=$1 # first argument to script
PY_SRC_REPO="docs/source/ingest/source_connectors/code/python/"
SH_SRC_REPO="docs/source/ingest/source_connectors/code/bash/"
SRC_TARGET_DIR=$2 # second argument to script

# Clone the correct directories in the open source repo
cd "$WORK_DIR"
git init
git remote add -f origin https://github.com/Unstructured-IO/unstructured
git config core.sparseCheckout true
echo "$PY_DEST_REPO" >> .git/info/sparse-checkout
echo "$SH_DEST_REPO" >> .git/info/sparse-checkout
echo "$PY_SRC_REPO" >> .git/info/sparse-checkout
echo "$SH_SRC_REPO" >> .git/info/sparse-checkout
git pull origin main

cp -R "$WORK_DIR/$PY_DEST_REPO/." "$DEST_TARGET_DIR/"
cp -R "$WORK_DIR/$SH_DEST_REPO/." "$DEST_TARGET_DIR/"
cp -R "$WORK_DIR/$PY_SRC_REPO/." "$SRC_TARGET_DIR/"
cp -R "$WORK_DIR/$SH_SRC_REPO/." "$SRC_TARGET_DIR/"

function to_mdx() {
    for f in *.py
    do sed -i '1i```python\' $f
    sed -i '$ a ```' $f
    mv $f $f.mdx
    done

    for f in *.sh
    do sed -i '1i```bash\' $f
    sed -i '$ a ```' $f
    mv $f $f.mdx
    done
}

# Convert the destination_connectors to markdown
cd "$DEST_TARGET_DIR"
to_mdx

# Convert the source_connectors to markdown
cd "$SRC_TARGET_DIR"
to_mdx

rm -rf "$WORK_DIR"

echo "Markdown files created in $DEST_TARGET_DIR and $SRC_TARGET_DIR"