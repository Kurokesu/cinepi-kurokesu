#!/usr/bin/bash
# CinePI unified launcher (works on desktop Trixie and Lite + Cage)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_TYPE="${1:-release}"
BINARY="$REPO_DIR/build/$BUILD_TYPE/cinepi"

if [ ! -f "$BINARY" ]; then
    echo "Binary not found: $BINARY"
    echo "Build first: ./scripts/build.sh $BUILD_TYPE"
    exit 1
fi

echo "Starting CinePI ($BUILD_TYPE)"
echo "Using: $BINARY"

export CINEPI_CONFIG_DIR="$REPO_DIR/config"
export CINEPI_SKIP_SOUND=1
export LIBCAMERA_LOG_LEVELS="${LIBCAMERA_LOG_LEVELS:-RPiAgc:ERROR,RPiCcm:ERROR}"

# Kill competing libcamera processes
pkill -x rpicam-still 2>/dev/null || true
pkill -x rpicam-vid 2>/dev/null || true

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

# Check if a Wayland compositor is already running (desktop environment)
WAYLAND_SOCKET="$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY:-wayland-0}"
if [ -S "$WAYLAND_SOCKET" ]; then
    echo "Wayland compositor detected, running directly"
    export QT_QPA_PLATFORM=wayland
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    export WLR_NO_HARDWARE_CURSORS=1
    exec "$BINARY"
else
    echo "No compositor found, launching via Cage"
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_LIBINPUT_NO_DEVICES=1
    exec cage -- "$BINARY"
fi
