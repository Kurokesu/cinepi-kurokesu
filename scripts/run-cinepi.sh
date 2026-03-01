#!/usr/bin/bash
# CinePI unified launcher
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
BINARY="$REPO_DIR/build/cinepi"

if [ ! -x "$BINARY" ]; then
    echo "Binary not found: $BINARY"
    echo "Build with: cd $REPO_DIR && mkdir -p build && cd build && cmake .. && make -j4"
    exit 1
fi

export CINEPI_CONFIG_DIR="$REPO_DIR/config"
export CINEPI_SKIP_SOUND=1

# Wayland display setup
export XDG_RUNTIME_DIR=/run/user/1000
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# Suppress per-frame libcamera warnings (no lux calibration data)
export LIBCAMERA_LOG_LEVELS="${LIBCAMERA_LOG_LEVELS:-RPiAgc:ERROR,RPiCcm:ERROR}"

# Wait for Wayland compositor to be ready (up to 30 seconds)
WAYLAND_SOCKET="$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
TIMEOUT=30
ELAPSED=0
while [ ! -S "$WAYLAND_SOCKET" ]; do
    if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
        echo "Wayland socket not found after ${TIMEOUT}s, starting anyway..."
        break
    fi
    sleep 1
    ELAPSED=$((ELAPSED + 1))
done

exec "$BINARY"
