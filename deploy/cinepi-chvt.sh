#!/bin/sh
# Wait for Cage to create the Wayland socket before switching VT.
# This ensures splash stays visible until the app is ready to render.
# Uses XDG_RUNTIME_DIR inherited from the service environment.
SOCKET="${XDG_RUNTIME_DIR:-/run/user/1000}/wayland-0"
i=0
while [ ! -e "$SOCKET" ] && [ "$i" -lt 50 ]; do
    sleep 0.1
    i=$((i + 1))
done

setterm --cursor off > /dev/tty7 2>/dev/null
/usr/bin/chvt 7
