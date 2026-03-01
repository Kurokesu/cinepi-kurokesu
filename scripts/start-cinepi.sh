#!/usr/bin/bash
# CinePI full-stack launcher
# Starts cinepi-raw (backend) and cinepi-qt (GUI) together.
# Killing this script (or the GUI) tears down both processes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cleanup() {
    if [ -n "${RAW_PID:-}" ] && kill -0 "$RAW_PID" 2>/dev/null; then
        kill "$RAW_PID" 2>/dev/null
        wait "$RAW_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Start cinepi-raw in the background
"$SCRIPT_DIR/run-raw.sh" &
RAW_PID=$!

# Give the backend a moment to open the camera and create shared memory
sleep 2

# Start cinepi-qt in the foreground (closing the GUI stops everything)
exec "$SCRIPT_DIR/run-qt-gui.sh"
