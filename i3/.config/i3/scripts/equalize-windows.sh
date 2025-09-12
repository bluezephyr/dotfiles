#!/usr/bin/env bash
# Equalize windows horizontally in current workspace
# - Flattens horizontal splits
# - Preserves vertical splits (so they stay as columns)

ws=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')

# Flatten horizontal split containers
readarray -t hcontainers < <(i3-msg -t get_tree \
  | jq -r --arg ws "$ws" '
      .. | select(.type? == "workspace" and .name == $ws)
         | recurse(.nodes[]?)
         | select(.layout? == "splith") | .id')

for cid in "${hcontainers[@]}"; do
  # Move each child window of this container to the workspace root
  readarray -t children < <(i3-msg -t get_tree \
    | jq -r --argjson id "$cid" '
        .. | select(.id? == $id) | .nodes[]? | select(.window? != null) | .id')
  for win in "${children[@]}"; do
    i3-msg "[con_id=$win] focus; floating disable; move to workspace \"$ws\"" >/dev/null
  done
done

# Get all top-level children of the workspace (windows + vertical containers)
readarray -t cols < <(i3-msg -t get_tree \
  | jq -r --arg ws "$ws" '
      .. | select(.type? == "workspace" and .name == $ws)
         | .nodes[]?.id')

count=${#cols[@]}
[ $count -eq 0 ] && exit 0

share=$((100 / count))

# Ensure root is horizontal split
i3-msg "workspace \"$ws\"; split h" >/dev/null

# Resize each column equally
for cid in "${cols[@]}"; do
  i3-msg "[con_id=$cid] resize set ${share} ppt" >/dev/null
done

