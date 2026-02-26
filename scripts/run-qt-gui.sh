#!/usr/bin/bash
# CinePI Qt Quick GUI launcher

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

export XDG_RUNTIME_DIR=/run/user/1000
export QT_QPA_PLATFORM=wayland
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

# For EGLFS (direct framebuffer, bypassing compositor):
# export QT_QPA_PLATFORM=eglfs
# export QT_QPA_EGLFS_INTEGRATION=eglfs_kms

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

exec "$REPO_DIR/cinepi-qt/build/cinepi-qt" "$@"
