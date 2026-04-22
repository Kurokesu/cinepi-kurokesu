#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Build CinePi app
#
# Usage: ./scripts/build.sh
#
# Output: build/cinepi

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$REPO_DIR/build"
CINEPI_TAG="build"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "unknown argument: $arg" ;;
    esac
done

header "cinepi build"
log "Build dir: $BUILD_DIR"

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake "$REPO_DIR" -Wno-dev

make -j"$(nproc)"

log "Binary: $BUILD_DIR/cinepi"
log "Run as a service: cinepictl restart"
