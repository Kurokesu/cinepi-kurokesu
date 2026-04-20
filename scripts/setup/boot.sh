#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Configure kernel command line and disable distracting services/timers
# so boot is quick and silent.
# Safe to re-run. Requires sudo.
#
# Usage:
#   sudo scripts/setup/boot.sh
#
# Does NOT handle Plymouth theme install/activation - that lives in splash.sh.
# boot.sh only sets the `quiet splash` kernel flags Plymouth needs.
#
# Changes:
#   - /boot/firmware/cmdline.txt : adds Plymouth + cursor-hiding kernel flags
#   - getty@tty1.service masked (no login prompt flashes on display TTY)
#   - Distracting services/timers disabled (NetworkManager-wait-online, etc.)

set -euo pipefail

CINEPI_TAG="boot"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

CMDLINE="/boot/firmware/cmdline.txt"

header "Configuring boot"

# Disable distracting services
DISABLE_SERVICES=(
    NetworkManager-wait-online.service
    ModemManager.service
    bluetooth.service
    cups.service
    triggerhappy.service
    apt-daily.service
    apt-daily-upgrade.service
)

for svc in "${DISABLE_SERVICES[@]}"; do
    systemctl disable "$svc" 2>/dev/null || true
done

log "Disabled ${#DISABLE_SERVICES[@]} services"

DISABLE_TIMERS=(
    man-db.timer
    apt-daily.timer
    apt-daily-upgrade.timer
    e2scrub_all.timer
)

for tmr in "${DISABLE_TIMERS[@]}"; do
    systemctl disable "$tmr" 2>/dev/null || true
done

log "Disabled ${#DISABLE_TIMERS[@]} timers"

# Kernel command line - minimum needed for Plymouth graphical splash.
if [ ! -f "$CMDLINE" ]; then
    warn "$CMDLINE not found; skipping cmdline edits"
else
    CMDLINE_CONTENT="$(cat "$CMDLINE")"

    CMDLINE_PARAMS=(quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0)
    CMDLINE_ADDITIONS=""
    for param in "${CMDLINE_PARAMS[@]}"; do
        if ! echo "$CMDLINE_CONTENT" | grep -qw "$param"; then
            CMDLINE_ADDITIONS="$CMDLINE_ADDITIONS $param"
        fi
    done

    if [ -n "$CMDLINE_ADDITIONS" ]; then
        # cmdline.txt is a single line - append to end.
        sed -i "s|$|$CMDLINE_ADDITIONS|" "$CMDLINE"
        log "cmdline additions:$CMDLINE_ADDITIONS"
    else
        log "cmdline already configured"
    fi
fi

# Mask getty on display TTY - no login prompt flashes before cinepi.service takes over.
systemctl mask getty@tty1.service 2>/dev/null || true
log "Masked getty@tty1.service"

log "Done. Reboot for changes to fully take effect."
