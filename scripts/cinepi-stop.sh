#!/bin/sh
# Tell systemd to stop printing status messages to console
kill -SIGRTMIN+21 1 2>/dev/null
# Kill fbi immediately (SIGKILL to prevent framebuffer restore flicker)
pkill -9 -x fbi 2>/dev/null
# Zero out framebuffer to erase splash pixel data
dd if=/dev/zero of=/dev/fb0 bs=1M count=4 2>/dev/null
# Clear all ttys that might have content
printf '\033[2J\033[H' > /dev/tty1 2>/dev/null
printf '\033[2J\033[H' > /dev/tty7 2>/dev/null
# Switch to tty11 (tty12 has kernel console, tty7 had Cage, tty1 had fbi)
/usr/bin/chvt 11
