#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Install cinepi.service (systemd unit) + PAM config.
# Safe to re-run. Requires sudo.
#
# Usage:
#   sudo scripts/setup/service.sh             # install unit, do NOT enable at boot
#   sudo scripts/setup/service.sh --enable    # install AND enable at boot (used by install.sh)
#
# Templates are substituted from deploy/cinepi.service.

set -euo pipefail

CINEPI_TAG="service"

# shellcheck source=common.sh
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

ENABLE_AT_BOOT=0
for arg in "$@"; do
    case "$arg" in
        --enable) ENABLE_AT_BOOT=1 ;;
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

REPO_DIR="$(resolve_repo_dir)"

header "Installing cinepi.service"
log "repo=$REPO_DIR user=$CINEPI_USER uid=$CINEPI_UID enable-at-boot=$ENABLE_AT_BOOT"

# Stop the service before we rewrite its unit file.
systemctl stop cinepi.service 2>/dev/null || true

# Render unit from template.
sed \
    -e "s|CINEPI_USER|$CINEPI_USER|g" \
    -e "s|CINEPI_REPO_DIR|$REPO_DIR|g" \
    "$REPO_DIR/deploy/cinepi.service" \
    > /etc/systemd/system/cinepi.service
log "Rendered /etc/systemd/system/cinepi.service"

# PAM config - required by Cage for a valid logind session on the tty.
cat > /etc/pam.d/cinepi <<'PAMEOF'
auth       required pam_unix.so
auth       required pam_env.so
account    required pam_unix.so
session    required pam_unix.so
session    required pam_loginuid.so
session    optional pam_systemd.so
PAMEOF
log "Wrote /etc/pam.d/cinepi"

systemctl daemon-reload
log "systemctl daemon-reload"

if [ "$ENABLE_AT_BOOT" -eq 1 ]; then
    systemctl enable cinepi.service
    log "Enabled cinepi.service for boot"
else
    log "Unit installed but NOT enabled at boot. Use 'sudo systemctl enable cinepi.service' to enable."
fi

log "Done."
