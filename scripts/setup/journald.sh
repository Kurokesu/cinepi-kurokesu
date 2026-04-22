#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Cap systemd-journald storage to protect SD-card / flash wear.
# Safe to re-run. Requires sudo.
#
# Usage:
#   sudo scripts/setup/journald.sh
#
# Writes /etc/systemd/journald.conf.d/cinepi.conf with size caps and rate limits.
# cinepi's per-frame DEBUG logs are compiled out in release builds, so normal
# operation writes little. The cap protects against surprise log floods.

set -euo pipefail

CINEPI_TAG="journald"

# shellcheck source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

DROPIN_DIR="/etc/systemd/journald.conf.d"
DROPIN_FILE="$DROPIN_DIR/cinepi.conf"

header "Configuring journald cap"

mkdir -p "$DROPIN_DIR"

cat > "$DROPIN_FILE" <<'EOF'
# Cinepi journald cap - protects SD/flash wear and prevents log floods.
# Tweak these if you need more log retention on a dev unit.
[Journal]
SystemMaxUse=64M
SystemKeepFree=512M
RuntimeMaxUse=32M
RateLimitIntervalSec=10s
RateLimitBurst=10000
EOF
log "Wrote $DROPIN_FILE"

systemctl restart systemd-journald
log "systemd-journald restarted with new caps"
