#!/usr/bin/env bash
# Robust i3 master-stack layout
# Focused window -> master (right, 60%)
# All others -> vertical stack on the left (40%)
# Runs repeatedly to promote new masters.

set -u

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
sanitized_ws=$(echo "$workspace" | sed 's/[^A-Za-z0-9_]/_/g')
mark_name="__i3_master_${sanitized_ws}"

# Collect all tiled windows (ignore floating)
readarray -t windows < <(i3-msg -t get_tree \
  | jq -r --arg ws "$workspace" '
      .. | select(.type? == "workspace" and .name == $ws) | ..
      | select(.window? != null and .floating == "auto_off")
      | .id')

count=${#windows[@]}
[ $count -lt 2 ] && exit 0

# Focused = candidate master
focused=$(i3-msg -t get_tree \
  | jq -r '.. | select(.nodes? or .floating_nodes?)? | select(.focused==true).id')

# Unmark any old master
i3-msg "[con_mark=$mark_name] unmark $mark_name" >/dev/null

# Flatten: move all to workspace root
for win in "${windows[@]}"; do
  i3-msg "[con_id=$win] focus; floating disable; move to workspace \"$workspace\"" >/dev/null
done

# Ensure root split is horizontal
i3-msg "workspace \"$workspace\"; split h" >/dev/null

# Promote focused -> master (right, mark it)
i3-msg "[con_id=$focused] focus; move right; split v; mark $mark_name" >/dev/null

# Put others on the left, tiled vertically
for win in "${windows[@]}"; do
  if [ "$win" != "$focused" ]; then
    i3-msg "[con_id=$win] focus; move left; split v" >/dev/null
  fi
done

# Resize explicitly: left 40%, right 60%
i3-msg "[con_mark=$mark_name] focus; resize set 60 ppt"
i3-msg "focus left; resize set 40 ppt"

# Return focus to master
i3-msg "[con_mark=$mark_name] focus" >/dev/null

