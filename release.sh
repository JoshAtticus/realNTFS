#!/bin/bash
set -e

# Build the app first
./build_app.sh

# Create a zip for release
echo "Zipping application..."
zip -r realNTFS.zip realNTFS.app

echo "Release Created: realNTFS.zip"
