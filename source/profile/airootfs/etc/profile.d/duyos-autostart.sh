# DuyOS: start the graphical session when the live user logs in on tty1.
# Skipped when booted with the "duyos.nodesktop" kernel parameter (text-mode boot entry),
# when already inside a graphical session, or on any other TTY / SSH login.
if [ "$(id -u)" -ne 0 ] && [ -z "${WAYLAND_DISPLAY}${DISPLAY}" ] \
   && [ "$(tty)" = "/dev/tty1" ] && ! grep -qw 'duyos.nodesktop' /proc/cmdline; then
    duyos-session
fi
