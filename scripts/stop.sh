#!/usr/bin/bash
# Stop all running CinePI instances (app + Cage compositor)
set -euo pipefail

if sudo systemctl is-active --quiet cinepi.service 2>/dev/null; then
    sudo systemctl stop cinepi.service
    echo "CinePI service stopped"
elif pkill -f "/cinepi$" 2>/dev/null; then
    echo "CinePI process stopped"
    pkill -x cage 2>/dev/null || true
    sleep 1
else
    echo "No CinePI process running"
fi
