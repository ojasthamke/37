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

# Print Flutter version and diagnostics
echo "Running Flutter doctor..."
./flutter/bin/flutter doctor

# Enable Web build
echo "Enabling Flutter Web..."
./flutter/bin/flutter config --enable-web

# Build Web release
echo "Building Flutter Web..."
./flutter/bin/flutter build web --release --no-tree-shake-icons

echo "Build complete!"
