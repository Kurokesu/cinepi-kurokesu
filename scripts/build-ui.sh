#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Build the standalone CinePiUiApp (the QDS-generated Qt Quick UI app).
# Used for live QML iteration without rebuilding the cinepi backend.
#
# Usage: ./scripts/build-ui.sh
#
# Output: build/ui/CinePiUiApp

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

SRC_DIR="$REPO_DIR/CinePiUi"
BUILD_DIR="$REPO_DIR/build/ui"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== CinePiUiApp build ==="
echo "Source: $SRC_DIR"
echo "Build:  $BUILD_DIR"

cmake "$SRC_DIR" -Wno-dev
make -j"$(nproc)"

echo
echo "Binary: $BUILD_DIR/CinePiUiApp"
