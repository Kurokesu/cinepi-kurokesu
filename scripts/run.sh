#!/usr/bin/bash
# CinePI unified launcher
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Auto-detect binary: prefer debug, then release
if [ -x "$REPO_DIR/build/debug/cinepi" ]; then
    BINARY="$REPO_DIR/build/debug/cinepi"
elif [ -x "$REPO_DIR/build/release/cinepi" ]; then
    BINARY="$REPO_DIR/build/release/cinepi"
elif [ -x "$REPO_DIR/build/cinepi" ]; then
    BINARY="$REPO_DIR/build/cinepi"
else
    echo "Binary not found. Build with: ./scripts/build.sh [debug|release]"
    exit 1
fi

echo "Using: $BINARY"

export CINEPI_CONFIG_DIR="$REPO_DIR/config"
export CINEPI_SKIP_SOUND=1

# Wayland display setup
export XDG_RUNTIME_DIR=/run/user/1000
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WLR_NO_HARDWARE_CURSORS=1

# Suppress per-frame libcamera warnings
export LIBCAMERA_LOG_LEVELS="${LIBCAMERA_LOG_LEVELS:-RPiAgc:ERROR,RPiCcm:ERROR}"

# Wait for Wayland compositor
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
