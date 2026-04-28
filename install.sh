#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, UAB Kurokesu
#
# cinepi-kurokesu installer
# Thin orchestrator over scripts/setup/* primitives.
#
# Installs cinepi as a kiosk that auto-starts on boot (via cinepi.service).
# For partial reconfigures on a dev machine, call individual primitives under
# scripts/setup/ directly instead of running this.
#
# Usage:
#   sudo ./install.sh          # fresh Pi full install
#   ./install.sh --help        # this message
#
# Requirements:
#   - Raspberry Pi 5
#   - Raspberry Pi OS Lite Trixie (64-bit, Debian 13)
#   - Internet connection (for apt)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/cinepi-install.log"
CINEPI_TAG="install"

# shellcheck source=scripts/common.sh
source "$REPO_DIR/scripts/common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

# Log everything to $LOG_FILE as well as the terminal.
exec > >(tee -a "$LOG_FILE") 2>&1
header "CinePi install started at $(date)"
log "Logging to $LOG_FILE"

header "Platform check"
if [ -f /proc/device-tree/model ]; then
    MODEL="$(tr -d '\0' < /proc/device-tree/model)"
    log "Model: $MODEL"
fi

ARCH="$(uname -m)"
[ "$ARCH" = "aarch64" ] || die "64-bit OS required (detected: $ARCH)"

log "Architecture: $ARCH"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    log "OS: ${PRETTY_NAME:-unknown}"
fi

log "Install user: $CINEPI_USER (uid=$CINEPI_UID)"

# Orchestrate setup primitives.
# Each script under scripts/setup/ is safe to re-run and can be used standalone.
# Order: configure everything first, enable the service last. If install is
# interrupted before service.sh runs, nothing auto-starts in a partial state
# on the next boot, user just re-runs install.sh.

"$REPO_DIR/scripts/setup/deps.sh"

header "Building CinePi"

# Build runs as the cinepi user, not root, so build artifacts end up user-owned.
sudo -u "$CINEPI_USER" "$REPO_DIR/scripts/build.sh"
log "Binary: $REPO_DIR/build/cinepi"

"$REPO_DIR/scripts/setup/storage.sh"
"$REPO_DIR/scripts/setup/overlays.sh"
"$REPO_DIR/scripts/setup/boot.sh"
"$REPO_DIR/scripts/setup/splash.sh"
"$REPO_DIR/scripts/setup/journald.sh"
"$REPO_DIR/scripts/setup/service.sh" --enable

# PATH-install cinepictl.
# Symlink, so edits to scripts/cinepictl.sh are live immediately.
header "Installing cinepictl command"

ln -sf "$REPO_DIR/scripts/cinepictl.sh" /usr/local/bin/cinepictl
log "Symlinked /usr/local/bin/cinepictl -> $REPO_DIR/scripts/cinepictl.sh"

header "Installation complete"

cat <<EOF
CinePi installed.

  User:    $CINEPI_USER
  Binary:  $REPO_DIR/build/cinepi
  Service: cinepi.service (enabled, auto-starts on boot)

Quick commands:
  sudo reboot                            # boot into kiosk
  cinepictl status                       # service state (post-install)
  cinepictl logs -f                      # tail logs
  scripts/build.sh && cinepictl restart
                                         # apply code changes

Sensor / display overlays are not auto-configured. Edit /boot/firmware/config.txt
to add e.g.:
  camera_auto_detect=0
  dtoverlay=imx283

Install log: $LOG_FILE
EOF
