#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Install APT dependencies for cinepi.
# Safe to re-run. Requires sudo (calls apt-get).
#
# Usage:
#   sudo scripts/setup/deps.sh              # production deps only
#   sudo scripts/setup/deps.sh --enable-ui-dev   # + deps for building CinePiUiApp
#
# --enable-ui-dev adds qt6-quicktimeline-dev, needed to compile CinePiUi/Dependencies/
# (Timeline-using Flow components). Only required by scripts/build-ui.sh.

set -euo pipefail

CINEPI_TAG="deps"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ENABLE_UI_DEV=0
for arg in "$@"; do
    case "$arg" in
        --enable-ui-dev) ENABLE_UI_DEV=1 ;;
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

header "Installing cinepi apt dependencies"

log "Updating package lists..."
apt-get update

log "Installing build tools..."
apt-get install -y \
    build-essential cmake pkg-config git

log "Installing Cage kiosk compositor..."
apt-get install -y cage

log "Installing Qt6 core + QML modules..."
apt-get install -y \
    qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts qml6-module-qtquick-window \
    qt6-shader-baker qt6-shadertools-dev

log "Installing libcamera and rpicam-apps..."
apt-get install -y libcamera-dev librpicam-app-dev

log "Installing graphics libraries..."
apt-get install -y \
    libegl-dev libgles-dev libdrm-dev

log "Installing camera backend dependencies..."
apt-get install -y \
    libboost-dev libboost-program-options-dev \
    libjpeg-dev libtiff-dev \
    libexif-dev libpng-dev \
    libspdlog-dev libjsoncpp-dev \
    libasound2-dev libudev-dev

log "Installing Plymouth..."
apt-get install -y plymouth plymouth-themes

if [ "$ENABLE_UI_DEV" -eq 1 ]; then
    log "Installing UI-dev extras (--enable-ui-dev)..."
    apt-get install -y qt6-quicktimeline-dev
fi

log "Done. All apt dependencies installed."
