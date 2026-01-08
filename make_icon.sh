#!/bin/bash

# Create icon.png using the swift script
swift generate_icon.swift

# Create iconset folder
mkdir realNTFS.iconset

# Generate required sizes
sips -z 16 16     icon.png --out realNTFS.iconset/icon_16x16.png
sips -z 32 32     icon.png --out realNTFS.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out realNTFS.iconset/icon_32x32.png
sips -z 64 64     icon.png --out realNTFS.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out realNTFS.iconset/icon_128x128.png
sips -z 256 256   icon.png --out realNTFS.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out realNTFS.iconset/icon_256x256.png
sips -z 512 512   icon.png --out realNTFS.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out realNTFS.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out realNTFS.iconset/icon_512x512@2x.png

# Create .icns file
iconutil -c icns realNTFS.iconset

# Clean up
rm -rf realNTFS.iconset
rm icon.png

echo "Created realNTFS.icns"
