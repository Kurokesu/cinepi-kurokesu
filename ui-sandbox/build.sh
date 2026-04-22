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
CINEPI_TAG="ui-sandbox"

# shellcheck source=../scripts/common.sh
source "$REPO_DIR/scripts/common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "unknown argument: $arg" ;;
    esac
done

header "ui-sandbox build"
log "Source: $SRC_DIR"
log "Build:  $BUILD_DIR"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$SRC_DIR" -Wno-dev
make -j"$(nproc)"

log "Binary: $BUILD_DIR/ui-sandbox"
