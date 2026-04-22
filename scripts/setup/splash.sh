#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Install and activate the cinepi Plymouth boot-splash theme.
# Safe to re-run. Requires sudo.
#
# Usage:
#   sudo scripts/setup/splash.sh
#
# Owns all Plymouth concerns:
#   - Copies theme files into /usr/share/plymouth/themes/cinepi/
#   - Runs plymouth-set-default-theme -R cinepi (rebuilds initramfs)
#   - Writes /etc/systemd/system.conf.d/quiet.conf (suppresses systemd status lines)
#
# Kernel TGA splash (pre-Plymouth) is intentionally NOT installed here -
# HyperPixel / DPI displays don't honour /lib/firmware/logo.tga. If HDMI support
# is added later, kernel splash can be reinstated as a separate primitive.

set -euo pipefail

CINEPI_TAG="splash"

# shellcheck source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

REPO_DIR="$(resolve_repo_dir)"
PLYMOUTH_SRC="$REPO_DIR/deploy/plymouth"
THEME_DST="/usr/share/plymouth/themes/cinepi"

header "Installing Plymouth theme"

mkdir -p "$THEME_DST"
for asset in cinepi.plymouth cinepi.script logo.png progress_bg.png progress_fill.png; do
    install -m 0644 "$PLYMOUTH_SRC/$asset" "$THEME_DST/"
done

log "Theme files copied to $THEME_DST"

log "Setting cinepi as default Plymouth theme (rebuilds initramfs)..."
/usr/sbin/plymouth-set-default-theme -R cinepi

# Suppress systemd status messages on console - so Plymouth owns the screen.
mkdir -p /etc/systemd/system.conf.d

cat > /etc/systemd/system.conf.d/quiet.conf <<'EOF'
[Manager]
ShowStatus=no
EOF

log "Wrote /etc/systemd/system.conf.d/quiet.conf"

log "Done. Plymouth cinepi theme installed and activated."
