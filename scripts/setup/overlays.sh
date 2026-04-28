#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, UAB Kurokesu
#
# Configure /boot/firmware/config.txt - device-tree overlays and firmware knobs.
# Safe to re-run (Raspberry Pi only). Requires sudo.
#
# Usage:
#   sudo scripts/setup/overlays.sh
#
# Adds:
#   - disable_splash=1   (disables rainbow splash)
#   - boot_delay=0       (skip kernel boot delay)
#   - dtparam=audio=off  (we don't use onboard audio)
#   - dtoverlay=disable-bt
#   - dtoverlay=disable-wifi
#
# Does NOT add camera or display overlays - those are user- and
# hardware-specific (e.g. dtoverlay=imx283, dtoverlay=vc4-kms-dpi-hyperpixel4sq).
# Users/follow-up scripts add those manually or via a separate step.

set -euo pipefail

CINEPI_TAG="overlays"

# shellcheck source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

CONFIG_TXT="/boot/firmware/config.txt"

if [ ! -f "$CONFIG_TXT" ]; then
    die "$CONFIG_TXT not found. Not a Raspberry Pi OS target?"
fi

header "Configuring $CONFIG_TXT"

CHANGED=0

add_line() {
    local line="$1"
    if grep -qxF "$line" "$CONFIG_TXT"; then
        log "already set: $line"
    else
        echo "$line" >> "$CONFIG_TXT"
        log "added: $line"
        CHANGED=1
    fi
}

add_line "disable_splash=1"
add_line "boot_delay=0"
add_line "dtparam=audio=off"
add_line "dtoverlay=disable-bt"
add_line "dtoverlay=disable-wifi"

if [ "$CHANGED" -eq 1 ]; then
    log "Changes written."
else
    log "No changes needed."
fi
