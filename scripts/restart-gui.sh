#!/usr/bin/bash
# Restart only the CinePI Qt GUI. Does not touch redis or cinepi-raw.
# Use this when the camera backend is already running (e.g. from boot or left running).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Stopping cinepi-qt..."
pkill -f cinepi-qt 2>/dev/null || true
sleep 1

echo "Starting cinepi-qt..."
exec "$REPO_DIR/scripts/run-qt-gui.sh" "$@"
