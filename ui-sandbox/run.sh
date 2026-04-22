#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Run the ui-sandbox app for QML iteration. Loads QML live from
# $REPO_DIR/CinePiUi, so edits you push from the host show up on next
# launch without a rebuild. No camera backend.
#
# Launched via systemd-run as a transient unit (ui-sandbox.service)
# that mirrors cinepi.service's session setup (same user, PAM, tty1)
# so wlroots/libseat have VT access. Requires sudo.
#
# Usage: ./ui-sandbox/run.sh
#
# Stop cinepi.service first (cinepictl stop) - tty1 can only host one.
# To tail output in another shell: journalctl -fu ui-sandbox

set -euo pipefail

SANDBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SANDBOX_DIR")"

for arg in "$@"; do
    case "$arg" in
        -h|--help) sed -n '5,17p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *) echo "unknown argument: $arg" >&2; exit 1 ;;
    esac
done

BINARY="$REPO_DIR/build/ui/ui-sandbox"
if [ ! -x "$BINARY" ]; then
    echo "ui-sandbox binary not found: $BINARY" >&2
    echo "Build first: $SANDBOX_DIR/build.sh" >&2
    exit 1
fi

QML_ROOT="$REPO_DIR/CinePiUi"
[ -d "$QML_ROOT" ] || { echo "QML root missing: $QML_ROOT" >&2; exit 1; }

UNIT=ui-sandbox
sudo systemctl stop "${UNIT}.service" 2>/dev/null || true

cleanup() {
    echo
    echo "Stopping ${UNIT}.service..."
    sudo systemctl stop "${UNIT}.service" >/dev/null 2>&1 || true
    exit 0
}
trap cleanup INT TERM

echo "Launching ui-sandbox as transient unit ${UNIT}.service"
echo "Binary:   $BINARY"
echo "QML root: $QML_ROOT"
echo "Tail output in another shell: journalctl -fu ${UNIT}"
echo "Ctrl+C to stop"

sudo systemd-run \
    --unit="$UNIT" \
    --quiet \
    --property=User="$USER" \
    --property=PAMName=cinepi \
    --property=TTYPath=/dev/tty1 \
    --property=StandardInput=tty-fail \
    --property=StandardOutput=journal \
    --property=StandardError=journal \
    --property=SyslogIdentifier="$UNIT" \
    --property=Environment=XCURSOR_SIZE=1 \
    --property=Environment=XCURSOR_THEME=transparent \
    --property=Environment=CINEPI_UI_QML_ROOT="$QML_ROOT" \
    /usr/bin/cage -- "$BINARY"

while systemctl is-active --quiet "${UNIT}.service"; do
    sleep 1
done
