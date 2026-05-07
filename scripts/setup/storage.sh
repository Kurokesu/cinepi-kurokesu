#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, UAB Kurokesu
#
# Configure external storage mount at /media/RAW for CinemaDNG recording.
# Safe to re-run. Requires sudo.
#
# Usage:
#   sudo scripts/setup/storage.sh
#
# If an NVMe drive is detected and not already in fstab, adds an fstab entry
# for the first NVMe partition (exfat, nofail) and mounts it. Without NVMe,
# the mount point is still created but remains empty - the user is expected
# to attach external storage later.

set -euo pipefail

CINEPI_TAG="storage"

# shellcheck source=../common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../common.sh"

for arg in "$@"; do
    case "$arg" in
        -h|--help) help_text; exit 0 ;;
        *) die "Unknown argument: $arg" ;;
    esac
done

require_root

CINEPI_GID="$(id -g "$CINEPI_USER")"

header "Configuring storage"

mkdir -p /media/RAW
log "Ensured /media/RAW exists"

if ! lsblk | grep -q "nvme"; then
    warn "No NVMe detected. Recording to /media/RAW requires external storage."
    exit 0
fi

log "NVMe detected"

NVME_PART="$(lsblk -lnp -o NAME,TYPE | awk '/nvme.*part/ {print $1; exit}' || true)"
if [ -z "${NVME_PART:-}" ]; then
    warn "NVMe device found but no partition - format it and re-run this script."
    exit 0
fi
log "NVMe partition: $NVME_PART"

if grep -q "/media/RAW" /etc/fstab; then
    log "/media/RAW already in /etc/fstab - leaving it alone"
    exit 0
fi

UUID="$(blkid -s UUID -o value "$NVME_PART" 2>/dev/null || true)"
if [ -z "$UUID" ]; then
    warn "Could not read UUID of $NVME_PART - format it first, then re-run."
    exit 0
fi

echo "UUID=$UUID /media/RAW exfat defaults,nofail,uid=$CINEPI_UID,gid=$CINEPI_GID 0 0" >> /etc/fstab
log "Added fstab entry (UUID=$UUID)"

if mount /media/RAW 2>/dev/null; then
    log "Mounted /media/RAW"
else
    warn "Could not mount /media/RAW - check filesystem type and format if needed."
fi
