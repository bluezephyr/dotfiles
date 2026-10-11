#!/usr/bin/env bash
#
# Included by kitty.conf (geninclude). Use a larger font when no external
# monitor is connected. kitty re-runs this on config reload (SIGUSR1), which
# ~/.config/i3/scripts/display-mode sends when the monitor setup changes.

if ! ~/.local/scripts/has-external-monitor; then
    echo "font_size 13"
fi
