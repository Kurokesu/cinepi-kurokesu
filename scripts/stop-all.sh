#!/usr/bin/bash
# Stop all CinePI processes (services and manual instances)

echo "Stopping cinepi-qt..."
sudo systemctl stop cinepi-qt.service 2>/dev/null || true
pkill -f cinepi-qt 2>/dev/null || true

echo "Stopping cinepi-raw..."
sudo systemctl stop cinepi-raw.service 2>/dev/null || true
pkill -f cinepi-raw 2>/dev/null || true
pkill -f run-raw.sh 2>/dev/null || true

sleep 1

if pgrep -f 'cinepi-raw|cinepi-qt' > /dev/null 2>&1; then
    echo "Force killing remaining processes..."
    pkill -9 -f cinepi-raw 2>/dev/null || true
    pkill -9 -f cinepi-qt 2>/dev/null || true
    sleep 1
fi

echo "All CinePI processes stopped."
