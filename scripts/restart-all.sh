#!/usr/bin/bash
# Restart the full CinePI stack: Redis → cinepi-raw → cinepi-qt
# Run from repo root. For GUI-only restart use restart-gui.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "Stopping cinepi-qt..."
pkill -f cinepi-qt 2>/dev/null || true
sleep 1

echo "Restarting redis-server..."
sudo systemctl restart redis-server.service
sleep 1

echo "Stopping any existing cinepi-raw..."
sudo systemctl stop cinepi-raw.service 2>/dev/null || true
pkill -f cinepi-raw 2>/dev/null || true
pkill -f run-raw.sh 2>/dev/null || true
sleep 2

echo "Starting cinepi-raw..."
sudo systemctl start cinepi-raw.service
sleep 3

echo "Starting cinepi-qt..."
exec "$REPO_DIR/scripts/run-qt-gui.sh" "$@"
