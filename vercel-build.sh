#!/bin/bash

# Exit on any error
set -e

# Clone Flutter if it doesn't exist, otherwise update
if [ -d "flutter" ]; then
  echo "Updating Flutter..."
  cd flutter
  git fetch --depth 1
  git reset --hard origin/stable
  cd ..
else
  echo "Cloning Flutter stable branch..."
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git
fi

# Set path to include Flutter bin
export PATH="$PATH:$(pwd)/flutter/bin"

# Enable Web build
echo "Enabling Flutter Web..."
flutter config --enable-web

# Build Web release
echo "Building Flutter Web..."
flutter build web --release

echo "Build complete!"
