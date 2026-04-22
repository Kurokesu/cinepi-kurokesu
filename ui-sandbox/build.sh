#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Build the ui-sandbox app: a thin harness for iterating on CinePiUi
# QML without the camera backend.
#
# Usage: ./ui-sandbox/build.sh
#
# Output: build/ui/ui-sandbox

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SRC_DIR")"
BUILD_DIR="$REPO_DIR/build/ui"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== ui-sandbox build ==="
echo "Source: $SRC_DIR"
echo "Build:  $BUILD_DIR"

cmake "$SRC_DIR" -Wno-dev
make -j"$(nproc)"

echo
echo "Binary: $BUILD_DIR/ui-sandbox"
