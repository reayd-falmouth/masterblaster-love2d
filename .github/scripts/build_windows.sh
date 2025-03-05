#!/bin/bash

set -e

# Parameters
LOVE_VERSION=${1:-"11.5"}
ARCH=${2:-"win64"}
GAME_NAME="chaosbomber"
LOVE_DOWNLOAD_URL="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-${ARCH}.zip"
BUILD_DIR="build"
OUTPUT_ZIP="${GAME_NAME}-${LOVE_VERSION}-${ARCH}.zip"

# Ensure dependencies
command -v wget >/dev/null 2>&1 || { echo "wget is required but not installed. Aborting."; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required but not installed. Aborting."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo "unzip is required but not installed. Aborting."; exit 1; }

# Create necessary directories
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Download and extract LÖVE
echo "Downloading LÖVE ${LOVE_VERSION} for ${ARCH}..."
wget -q --show-progress -O "$BUILD_DIR/love.zip" "$LOVE_DOWNLOAD_URL"
unzip -q "$BUILD_DIR/love.zip" -d "$BUILD_DIR"
mv "$BUILD_DIR/love-${LOVE_VERSION}-${ARCH}" "$BUILD_DIR/love"

# Create .love archive
echo "Creating ${GAME_NAME}.love..."
cd src/chaosbomber || exit
zip -9 -r "../../${BUILD_DIR}/${GAME_NAME}.love" .
cd - > /dev/null

# Combine love.exe and the .love file into a Windows executable
echo "Creating Windows executable..."
cat "$BUILD_DIR/love/love.exe" "$BUILD_DIR/${GAME_NAME}.love" > "$BUILD_DIR/${GAME_NAME}.exe"

# Prepare final distribution folder
echo "Preparing Windows distribution folder..."
DIST_DIR="${BUILD_DIR}/${GAME_NAME}-windows"
mkdir -p "$DIST_DIR"
mv "$BUILD_DIR/${GAME_NAME}.exe" "$DIST_DIR/"
cp "$BUILD_DIR/love/"*.dll "$DIST_DIR/"
cp "$BUILD_DIR/love/license.txt" "$DIST_DIR/"

# Create final ZIP archive
echo "Creating final ZIP archive..."
cd "$BUILD_DIR" || exit
zip -9 -r "../$OUTPUT_ZIP" "$(basename "$DIST_DIR")"
cd - > /dev/null

echo "Build complete: $OUTPUT_ZIP"
