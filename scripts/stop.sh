#!/usr/bin/bash
# Stop all running CinePI instances
set -euo pipefail

if pkill -f "/cinepi$" 2>/dev/null; then
    echo "CinePI stopped"
    sleep 1
elif sudo systemctl is-active --quiet cinepi.service 2>/dev/null; then
    sudo systemctl stop cinepi.service
    echo "CinePI service stopped"
else
    echo "No CinePI process running"
fi
