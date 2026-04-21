#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Run the standalone CinePiUiApp. Primarily for QML iteration:
# stop cinepi.service, sync QML from host, run-ui.sh --qml, see result.
#
# Usage:
#   ./scripts/run-ui.sh            # compiled-in QML
#   ./scripts/run-ui.sh --qml      # live QML from $REPO_DIR/CinePiUi
#
# --qml sets CINEPI_UI_QML_ROOT so the app loads App.qml from disk. Edit
# .qml files, restart the app to see changes. Set CINEPI_UI_QML_ROOT
# explicitly to point elsewhere (e.g. a synced-from-host staging dir).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

LIVE_QML=0
for arg in "$@"; do
    case "$arg" in
        --qml) LIVE_QML=1 ;;
        -h|--help)
            sed -n '5,14p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *) echo "unknown argument: $arg" >&2; exit 1 ;;
    esac
done

BINARY="$REPO_DIR/build/ui/CinePiUiApp"
if [ ! -x "$BINARY" ]; then
    echo "UI binary not found: $BINARY" >&2
    echo "Build first: $SCRIPT_DIR/build-ui.sh" >&2
    exit 1
fi

if [ "$LIVE_QML" = 1 ]; then
    : "${CINEPI_UI_QML_ROOT:=$REPO_DIR/CinePiUi}"
    export CINEPI_UI_QML_ROOT
    [ -d "$CINEPI_UI_QML_ROOT" ] || {
        echo "CINEPI_UI_QML_ROOT does not exist: $CINEPI_UI_QML_ROOT" >&2; exit 1; }
    echo "Live QML root: $CINEPI_UI_QML_ROOT"
fi

echo "Starting CinePiUiApp"
echo "Using: $BINARY"

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

WAYLAND_SOCKET="$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY:-wayland-0}"
if [ -S "$WAYLAND_SOCKET" ]; then
    echo "Wayland compositor detected, running directly"
    export QT_QPA_PLATFORM=wayland
    export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
    export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
    exec "$BINARY"
else
    echo "No compositor found, launching via Cage"
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_LIBINPUT_NO_DEVICES=1
    exec cage -- "$BINARY"
fi
