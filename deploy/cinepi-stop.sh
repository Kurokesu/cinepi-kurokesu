#!/bin/sh
# Tell systemd to stop printing status messages to console
kill -SIGRTMIN+21 1 2>/dev/null
# Clear ttys that might have content
printf '\033[2J\033[H' > /dev/tty7 2>/dev/null
# Switch to unused tty (tty12 has kernel console, tty7 had Cage)
/usr/bin/chvt 11
