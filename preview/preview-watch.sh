#!/usr/bin/bash
# QML Preview file watcher for RPi
# Restarts the preview app whenever QML/config/image files change
#
# Usage: ./preview-watch.sh [project-dir] [binary-path]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${1:-$SCRIPT_DIR/../CinePiUi}"
BINARY="${2:-$SCRIPT_DIR/build/qml-preview}"

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [ ! -x "$BINARY" ]; then
    echo "Binary not found: $BINARY"
    echo "Build first: cd preview/build && cmake .. && make -j\$(nproc)"
    exit 1
fi

if ! command -v inotifywait &> /dev/null; then
    echo "Installing inotify-tools..."
    sudo apt-get install -y inotify-tools
fi

# Qt environment (mirrors .qmlproject env block)
export QML_COMPAT_RESOLVE_URLS_ON_ASSIGNMENT=1
export QT_ENABLE_HIGHDPI_SCALING=0
export QT_LOGGING_RULES="qt.qml.connections=false"
export QT_QUICK_CONTROLS_HOVER_ENABLED=0
export QT_VIRTUALKEYBOARD_DESKTOP_DISABLE=1

# Wayland display
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/1000}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export WLR_NO_HARDWARE_CURSORS=1

echo "=== QML Preview Watcher ==="
echo "Project: $PROJECT_DIR"
echo "Binary:  $BINARY"
echo "Press Ctrl+C to stop"
echo ""

cleanup() {
    echo "Stopping..."
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

while true; do
    echo "[$(date '+%H:%M:%S')] Starting preview..."
    "$BINARY" "$PROJECT_DIR" &
    PID=$!

    inotifywait -r -q \
        -e modify,create,delete \
        --include '\.(qml|conf|jpg|png|ttf)$' \
        "$PROJECT_DIR"

    echo "[$(date '+%H:%M:%S')] Change detected, restarting..."
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    sleep 0.2
done
