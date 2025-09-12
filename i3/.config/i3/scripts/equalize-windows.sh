#!/bin/bash
# Resize all tiled windows in the current workspace equally (horizontal split)

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')

# Collect all tiling windows (skip floating)
windows=($(i3-msg -t get_tree \
  | jq -r --arg ws "$workspace" '
        .. | select(.name? == $ws).nodes[]
        | .. | select(.window? != null and .floating == "auto_off").id'))

count=${#windows[@]}
[ $count -eq 0 ] && exit 0

share=$((100 / count))

# Loop through and resize each
for win in "${windows[@]}"; do
  i3-msg "[con_id=$win] focus; resize set ${share} ppt"
done
