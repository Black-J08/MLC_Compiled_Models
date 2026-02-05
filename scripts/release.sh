#!/bin/bash
set -e

# Usage: ./release.sh v1.2.0 "Release Notes"

TAG=$1
NOTES=${2:-"Model Bundle Release"}
# Directories
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$REPO_ROOT/dist"

if [ -z "$TAG" ]; then
    echo "Usage: $0 <tag> [notes]"
    exit 1
fi

echo "Creating GitHub Release $TAG..."

# Check if dist dir exists and has zip files
if [ ! -d "$DIST_DIR" ]; then
    echo "Error: $DIST_DIR does not exist. Run compile_models.sh first."
    exit 1
fi

count=$(ls -1 "$DIST_DIR"/*.zip 2>/dev/null | wc -l)
if [ "$count" -eq 0 ]; then
    echo "Error: No .zip files found in $DIST_DIR."
    exit 1
fi

# Create Release
# --generate-notes helps if no notes provided, but here we output specific message
gh release create "$TAG" "$DIST_DIR"/*.zip \
    --title "Model Bundle $TAG" \
    --notes "$NOTES" \
    --repo "Black-J08/MLC_Compiled_Models"

echo "Release $TAG published successfully!"
