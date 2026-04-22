#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# Host-side. Sync CinePiUi/ to the target Pi and restart
# ui-sandbox.service so the running harness picks up the new QML.
#
# Initial run does a full rsync to establish the baseline. --watch mode
# then pushes individual files as they change (one rsync per file, not a
# tree diff), coalescing bursts so one save = one restart.
#
# Usage: ui-sandbox/sync.sh <ssh-target> [--watch] [--remote-path PATH] [--no-restart]
#
# Example: ui-sandbox/sync.sh cinepi --watch
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
#   3. ui-sandbox/run.sh running in another shell to see changes live.

set -euo pipefail

UI_SANDBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$UI_SANDBOX_DIR")"
CINEPI_TAG="sync"

# shellcheck source=../scripts/common.sh
source "$REPO_DIR/scripts/common.sh"

WATCH=0
RESTART=1
REMOTE_PATH='/var/tmp/cinepi-ui-sandbox/CinePiUi'
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

# SSH connection multiplexing: first ssh/scp opens a persistent control
# socket, subsequent invocations reuse it (no handshake). Makes per-file
# sync close to free.
SSH_CM_DIR="$(mktemp -d -t cinepi-sync-XXXXXX)"
SSH_OPTS=(
    -o BatchMode=yes
    -o ControlMaster=auto
    -o "ControlPath=$SSH_CM_DIR/cm-%C"
    -o ControlPersist=60s
)
cleanup() {
    ssh "${SSH_OPTS[@]}" -O exit "$TARGET" 2>/dev/null || true
    rm -rf "$SSH_CM_DIR"
}
trap cleanup EXIT

RSYNC_EXCLUDES=(
    --exclude=.git/
    --exclude=build/
    --exclude='*.user'
    --exclude='*.user.*'
)

# Extensions worth syncing. Everything else (QDS atomic-save tempfiles,
# generated .cmake/.h, editor swap files, ...) is ignored at the watcher.
is_watched() {
    case "$1" in
        *.qml|*.conf|*.png|*.jpg|*.jpeg|*.svg|*.webp|*.ttf|*.otf|*.woff|*.woff2|*.json|*.js) return 0 ;;
        *) return 1 ;;
    esac
}

rsync_ssh_cmd="ssh ${SSH_OPTS[*]}"

full_sync() {
    rsync -az --delete -e "$rsync_ssh_cmd" \
        "${RSYNC_EXCLUDES[@]}" \
        "$SRC_DIR/" "$TARGET:$REMOTE_PATH/"
}

sync_file() {
    local rel="$1"
    local dst_dir
    dst_dir="$REMOTE_PATH/$(dirname "$rel")"
    ssh "${SSH_OPTS[@]}" "$TARGET" "mkdir -p '$dst_dir'"
    rsync -az -e "$rsync_ssh_cmd" "$SRC_DIR/$rel" "$TARGET:$dst_dir/"
}

delete_file() {
    local rel="$1"
    ssh "${SSH_OPTS[@]}" "$TARGET" "rm -f '$REMOTE_PATH/$rel'"
}

restart_service() {
    [ "$RESTART" -eq 1 ] || return 0
    ssh "${SSH_OPTS[@]}" "$TARGET" "sudo -n systemctl restart ui-sandbox.service" \
        || warn "restart failed (is ui-sandbox.service running? NOPASSWD sudo configured?)"
}

log "target:      $TARGET"
log "remote path: $REMOTE_PATH"
log "restart:     $([ "$RESTART" -eq 1 ] && echo yes || echo no)"

ssh "${SSH_OPTS[@]}" "$TARGET" "mkdir -p '$REMOTE_PATH'" \
    || die "failed to reach $TARGET or create $REMOTE_PATH"

full_sync
log "initial sync done"
restart_service

[ "$WATCH" -eq 1 ] || exit 0

command -v inotifywait >/dev/null \
    || die "inotifywait not found (sudo apt install inotify-tools)"

log "watching $SRC_DIR for changes (Ctrl+C to stop)"

# Read events from inotifywait on FD 3 so we can keep shell state across
# the loop (unlike a `| while` pipeline, which subshells).
exec 3< <(inotifywait -mre modify,create,delete,move,close_write \
    --format '%e|%w%f' "$SRC_DIR")

process_batch() {
    # Collapse the batch to one op per path (latest event wins).
    declare -A ops
    local entry event path rel
    for entry in "$@"; do
        event="${entry%%|*}"
        path="${entry#*|}"
        rel="${path#"$SRC_DIR/"}"
        [ "$rel" != "$path" ] || continue
        is_watched "$rel" || continue
        case ",$event," in
            *,DELETE,*|*,MOVED_FROM,*) ops["$rel"]=delete ;;
            *)                          ops["$rel"]=sync ;;
        esac
    done

    [ "${#ops[@]}" -gt 0 ] || return 0

    local acted=0
    for rel in "${!ops[@]}"; do
        case "${ops[$rel]}" in
            delete) delete_file "$rel"; log "deleted $rel"; acted=1 ;;
            sync)   sync_file   "$rel"; log "synced  $rel"; acted=1 ;;
        esac
    done
    [ "$acted" -eq 1 ] && restart_service
}

while IFS= read -r line <&3; do
    batch=("$line")
    # Drain any follow-up events within 300 ms so a QDS atomic save or a
    # multi-file save coalesces into one restart.
    while IFS= read -r -t 0.3 more <&3; do
        batch+=("$more")
    done
    process_batch "${batch[@]}"
done
