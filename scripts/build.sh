#!/usr/bin/bash
# CinePI build script
# Usage: ./scripts/build.sh [debug|release]  (default: debug)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

BUILD_TYPE="${1:-debug}"

case "$BUILD_TYPE" in
    debug)   CMAKE_TYPE="Debug" ;;
    release) CMAKE_TYPE="Release" ;;
    *)
        echo "Usage: $0 [debug|release]"
        exit 1
        ;;
esac

BUILD_DIR="$REPO_DIR/build/$BUILD_TYPE"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

echo "=== CinePI $CMAKE_TYPE build ==="
echo "Build dir: $BUILD_DIR"

cmake "$REPO_DIR" \
    -DCMAKE_BUILD_TYPE="$CMAKE_TYPE" \
    -Wno-dev

make -j"$(nproc)"

echo ""
echo "Binary: $BUILD_DIR/cinepi"
echo "Run with: $REPO_DIR/scripts/run-cinepi.sh"
