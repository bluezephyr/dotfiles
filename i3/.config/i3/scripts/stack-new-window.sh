#!/usr/bin/env bash
# Send a newly created window straight into the stack of an active
# master-stack layout (see master-stack.sh), instead of leaving it beside
# master. Triggered by a for_window rule in the i3 config that marks each
# new window "__i3_newwin" before invoking this script, so the new window
# is identified directly rather than by (unreliable) current focus.
# No-op if the workspace has no active master-stack layout.

set -uo pipefail

new_win=$(i3-msg -t get_tree | jq -r '
  .. | objects | select(.marks? != null and (.marks | index("__i3_newwin")) != null) | .id')
[ -z "$new_win" ] && exit 0
i3-msg "[con_mark=__i3_newwin] unmark __i3_newwin" >/dev/null

tree=$(i3-msg -t get_tree)

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
sanitized_ws=$(echo "$workspace" | sed 's/[^A-Za-z0-9_]/_/g')
master_mark="__i3_master_${sanitized_ws}"
stack_mark="__i3_stack_${sanitized_ws}"

# Only act if a master-stack layout already exists here. Deliberately not
# checking master's exact position (e.g. a direct child of the pair):
# a manual "split" on the focused master (unrelated keybinding) nests it
# one level deeper without moving or unmarking it, and routing must keep
# working regardless -- it only needs both marks to exist somewhere.
master_exists=$(echo "$tree" | jq -r --arg m "$master_mark" '
  [.. | objects | select(.marks? != null and (.marks | index($m)) != null)] | length')
stack_exists=$(echo "$tree" | jq -r --arg s "$stack_mark" '
  [.. | objects | select(.marks? != null and (.marks | index($s)) != null)] | length')
{ [ "$master_exists" = "1" ] && [ "$stack_exists" = "1" ]; } || exit 0

# Skip floating windows (dialogs, popups) -- only route tiled ones.
floating=$(echo "$tree" | jq -r --arg w "$new_win" '
  .. | objects | select(.id? == ($w | tonumber)) | .floating')
[ "$floating" = "auto_off" ] || [ "$floating" = "user_off" ] || exit 0

master_id=$(echo "$tree" | jq -r --arg m "$master_mark" '
  .. | objects | select(.marks? != null and (.marks | index($m)) != null) | .id')
[ "$new_win" = "$master_id" ] && exit 0

# Already a stack member (shouldn't happen for a brand-new window, but
# "move to mark" errors on a no-op move).
stack_children=" $(echo "$tree" | jq -r --arg s "$stack_mark" '
  .. | objects | select(.marks? != null and (.marks | index($s)) != null) | .nodes[]?.id' | tr '\n' ' ') "
[[ "$stack_children" == *" $new_win "* ]] && exit 0

i3-msg "[con_id=$new_win] move container to mark $stack_mark" >/dev/null
