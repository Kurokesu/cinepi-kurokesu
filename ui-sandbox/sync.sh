#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Host-side. rsync CinePiUi/ to the target Pi, then restart
# ui-sandbox.service so the running harness picks up the new QML.
#
# Usage: ui-sandbox/sync.sh <ssh-target> [--watch] [--remote-path PATH] [--no-restart]
#
# Example: ui-sandbox/sync.sh kurokesu@cinepi.local --watch
#
# Prerequisites on the host:
#   - rsync, ssh
#   - inotify-tools (only for --watch): sudo apt install inotify-tools
#
# Prerequisites on the target:
#   1. Passwordless SSH from host. See https://github.com/Kurokesu/ssh-keyup
#   2. Passwordless sudo for the one restart command:
#        echo "$USER ALL=(root) NOPASSWD: /bin/systemctl restart ui-sandbox.service" \
#          | sudo tee /etc/sudoers.d/cinepi-ui-sandbox
#        sudo chmod 440 /etc/sudoers.d/cinepi-ui-sandbox
#   3. ui-sandbox/run.sh already running (in another shell) if you want
#      --no-restart omitted; otherwise nothing will pick up the changes.

set -euo pipefail

UI_SANDBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$UI_SANDBOX_DIR")"
CINEPI_TAG="sync"

# shellcheck source=../scripts/common.sh
source "$REPO_DIR/scripts/common.sh"

WATCH=0
RESTART=1
REMOTE_PATH='~/kurokesu-cinepi/CinePiUi'
TARGET=""

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)     help_text; exit 0 ;;
        --watch)       WATCH=1 ;;
        --no-restart)  RESTART=0 ;;
        --remote-path)
            [ $# -ge 2 ] || die "--remote-path requires a value"
            REMOTE_PATH="$2"
            shift
            ;;
        -*) die "unknown flag: $1" ;;
        *)
            [ -z "$TARGET" ] || die "extra positional argument: $1"
            TARGET="$1"
            ;;
    esac
    shift
done

[ -n "$TARGET" ] || die "missing <ssh-target>; see --help"

SRC_DIR="$REPO_DIR/CinePiUi"
[ -d "$SRC_DIR" ] || die "CinePiUi not found at $SRC_DIR"

RSYNC_EXCLUDES=(
    --exclude=.git/
    --exclude=build/
    --exclude='*.user'
    --exclude='*.user.*'
)

sync_once() {
    rsync -az --delete "${RSYNC_EXCLUDES[@]}" "$SRC_DIR/" "$TARGET:$REMOTE_PATH/"
    if [ "$RESTART" -eq 1 ]; then
        ssh -o BatchMode=yes "$TARGET" "sudo -n systemctl restart ui-sandbox.service" \
            || warn "restart failed (is ui-sandbox.service running? NOPASSWD sudo configured?)"
    fi
}

log "target:      $TARGET"
log "remote path: $REMOTE_PATH"
log "restart:     $([ "$RESTART" -eq 1 ] && echo yes || echo no)"

ssh -o BatchMode=yes "$TARGET" "mkdir -p $REMOTE_PATH" \
    || die "failed to create $REMOTE_PATH on $TARGET"

sync_once
log "initial sync done"

if [ "$WATCH" -eq 1 ]; then
    command -v inotifywait >/dev/null \
        || die "inotifywait not found (sudo apt install inotify-tools)"
    log "watching $SRC_DIR for changes (Ctrl+C to stop)"
    while path=$(inotifywait -qre modify,create,delete,move \
            --exclude '(\.git/|build/|\.user$)' \
            --format '%w%f' "$SRC_DIR"); do
        sleep 0.3
        sync_once
        log "synced (${path#"$SRC_DIR/"})"
    done
fi
