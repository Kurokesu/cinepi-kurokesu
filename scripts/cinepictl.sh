#!/usr/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (c) 2026, UAB Kurokesu. All rights reserved.
#
# cinepictl - control tool for cinepi.service.
# Use for post-install verification, dev iteration, and field support.
#
# Usage:
#   cinepictl start
#   cinepictl stop
#   cinepictl restart
#   cinepictl status
#   cinepictl logs [journalctl-args]     default: last 200 lines
#   cinepictl log-level <level>          trace|debug|info|warn|error|off
#   cinepictl help
#
# log-level writes a systemd drop-in (Environment=CINEPI_LOG_LEVEL). The app
# reads this on startup - restart the service to apply.

set -euo pipefail

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
CINEPI_TAG="cinepictl"

# shellcheck source=common.sh
source "$SCRIPT_DIR/common.sh"

SERVICE="cinepi.service"
DROPIN_DIR="/etc/systemd/system/${SERVICE}.d"
LOG_LEVEL_DROPIN="${DROPIN_DIR}/log-level.conf"

cmd_start()   { sudo systemctl start   "$SERVICE"; }
cmd_stop()    { sudo systemctl stop    "$SERVICE"; }
cmd_restart() { sudo systemctl restart "$SERVICE"; }
cmd_status()  { systemctl status "$SERVICE" --no-pager; }

cmd_logs() {
    local args=(-u "$SERVICE" -t cinepi --no-pager)
    if [ "$#" -eq 0 ]; then
        args+=(-n 200)
    else
        args+=("$@")
    fi
    journalctl "${args[@]}"
}

cmd_log_level() {
    local level="${1:-}"
    case "$level" in
        trace|debug|info|warn|error|off) ;;
        "") die "log-level requires an argument (trace|debug|info|warn|error|off)" ;;
        *)  die "invalid log level '$level' (trace|debug|info|warn|error|off)" ;;
    esac

    sudo install -d -m 0755 "$DROPIN_DIR"
    sudo tee "$LOG_LEVEL_DROPIN" >/dev/null <<EOF
[Service]
Environment=CINEPI_LOG_LEVEL=$level
EOF
    sudo systemctl daemon-reload
    log "wrote $LOG_LEVEL_DROPIN (CINEPI_LOG_LEVEL=$level)"
    log "restart to apply: cinepictl restart"
}

cmd="${1:-help}"
shift || true

case "$cmd" in
    start)          cmd_start ;;
    stop)           cmd_stop ;;
    restart)        cmd_restart ;;
    status)         cmd_status ;;
    logs)           cmd_logs "$@" ;;
    log-level)      cmd_log_level "$@" ;;
    -h|--help|help) help_text ;;
    *)              die "unknown command: $cmd (try 'cinepictl help')" ;;
esac
