#!/usr/bin/env bash

# This script will open a terminal (kitty) with the class set to
# scratchpad-kitty if it not already exists. The script needs the xdotool
# command to work.

if  [ -z "$(xdotool search --classname 'scratchpad-kitty')" ]; then
    kitty --class="scratchpad-kitty" tmux & sleep 0.5
fi

i3-msg "[class=scratchpad-kitty] scratchpad show; move position center"
