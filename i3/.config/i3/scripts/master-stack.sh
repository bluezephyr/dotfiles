#!/usr/bin/env bash
# i3 master-stack layout
# Focused window -> master (right, 65%)
# All others -> vertical stack on the left
# Runs repeatedly to promote new masters.
#
# Maintains an explicit, marked three-container tree:
#   pair (splith)
#     +-- stack (splitv, all non-focused windows)
#     +-- master (focused window)
#
# The pair/stack containers are reused across runs (windows are moved in
# and out via "move container to mark") rather than rebuilt from scratch
# each time. If no valid structure exists yet (first run, or the master
# window closed), it's (re)built.

set -uo pipefail

workspace=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
sanitized_ws=$(echo "$workspace" | sed 's/[^A-Za-z0-9_]/_/g')
master_mark="__i3_master_${sanitized_ws}"
stack_mark="__i3_stack_${sanitized_ws}"
pair_mark="__i3_pair_${sanitized_ws}"

tree=$(i3-msg -t get_tree)

# Collect all tiled (non-floating) window ids in the focused workspace.
readarray -t windows < <(echo "$tree" | jq -r --arg ws "$workspace" '
  .. | select(.type? == "workspace" and .name == $ws) | ..
  | select(.window? != null and (.floating == "auto_off" or .floating == "user_off"))
  | .id')

count=${#windows[@]}
[ "$count" -lt 2 ] && exit 0

# The currently focused tiled window in this workspace becomes master.
focused=$(echo "$tree" | jq -r --arg ws "$workspace" '
  .. | select(.type? == "workspace" and .name == $ws) | ..
  | select(.window? != null and .focused == true
           and (.floating == "auto_off" or .floating == "user_off"))
  | .id' | head -n1)
[ -z "$focused" ] && exit 0

others=()
for w in "${windows[@]}"; do
  [ "$w" != "$focused" ] && others+=("$w")
done

# Valid existing structure: pair, stack and master marks each exist
# exactly once. Deliberately not requiring master to be a *direct* child
# of the pair: an unrelated manual "split" on the focused master nests it
# one level deeper without moving or unmarking it, and that shouldn't
# force a full rebuild -- the reuse path below re-parents master properly
# again as soon as focus moves off of it.
valid=$(echo "$tree" | jq -r --arg p "$pair_mark" --arg m "$master_mark" --arg s "$stack_mark" '
  ([.. | objects | select(.marks? != null and (.marks | index($p)) != null)] | length) as $pc
  | ([.. | objects | select(.marks? != null and (.marks | index($m)) != null)] | length) as $mc
  | ([.. | objects | select(.marks? != null and (.marks | index($s)) != null)] | length) as $sc
  | if ($pc == 1 and $mc == 1 and $sc == 1) then "yes" else "no" end')

if [ "$valid" = "yes" ]; then
  old_master=$(echo "$tree" | jq -r --arg m "$master_mark" '
    .. | objects | select(.marks? != null and (.marks | index($m)) != null) | .id')

  # Skip windows already directly in the target container ("move to mark"
  # errors on a no-op move).
  stack_children=" $(echo "$tree" | jq -r --arg s "$stack_mark" '
    .. | objects | select(.marks? != null and (.marks | index($s)) != null) | .nodes[]?.id' | tr '\n' ' ') "
  pair_children=" $(echo "$tree" | jq -r --arg p "$pair_mark" '
    .. | objects | select(.marks? != null and (.marks | index($p)) != null) | .nodes[]?.id' | tr '\n' ' ') "

  # Drain every non-focused window into the stack.
  for w in "${others[@]}"; do
    [[ "$stack_children" == *" $w "* ]] && continue
    i3-msg "[con_id=$w] move container to mark $stack_mark" >/dev/null
  done

  if [ "$focused" != "$old_master" ]; then
    i3-msg "[con_mark=$master_mark] unmark $master_mark" >/dev/null
    if [[ "$pair_children" != *" $focused "* ]]; then
      i3-msg "[con_id=$focused] move container to mark $pair_mark" >/dev/null
    fi
    i3-msg "[con_id=$focused] mark $master_mark" >/dev/null
  fi
else
  # No valid pair: rebuild it, reusing the stack container if one still
  # exists (wrapping the whole stack container, not one of its leaves,
  # avoids leaving an orphaned wrapper behind).
  i3-msg "[con_mark=$master_mark] unmark $master_mark" >/dev/null
  i3-msg "[con_mark=$pair_mark] unmark $pair_mark" >/dev/null

  stack_container=$(echo "$tree" | jq -r --arg s "$stack_mark" '
    .. | objects | select(.marks? != null and (.marks | index($s)) != null) | .id')

  if [ -z "$stack_container" ]; then
    # No stack either: build one from a plain leaf.
    i3-msg "[con_mark=$stack_mark] unmark $stack_mark" >/dev/null
    anchor="${others[0]}"
    i3-msg "[con_id=$anchor] focus" >/dev/null
    i3-msg "split v" >/dev/null
    i3-msg "focus parent" >/dev/null
    i3-msg "mark $stack_mark" >/dev/null
    for w in "${others[@]:1}"; do
      i3-msg "[con_id=$w] move container to mark $stack_mark" >/dev/null
    done
    stack_leaf="$anchor"
  else
    stack_leaf=$(echo "$tree" | jq -r --arg s "$stack_mark" '
      .. | objects | select(.marks? != null and (.marks | index($s)) != null) | .nodes[0].id')
  fi

  # Wrap the stack container (reached via one of its children + one
  # "focus parent" hop) in a fresh horizontal split -- the new pair.
  i3-msg "[con_id=$stack_leaf] focus" >/dev/null
  i3-msg "focus parent" >/dev/null
  i3-msg "split h" >/dev/null
  i3-msg "focus parent" >/dev/null
  i3-msg "mark $pair_mark" >/dev/null

  i3-msg "[con_id=$focused] move container to mark $pair_mark" >/dev/null
  for w in "${others[@]}"; do
    i3-msg "[con_id=$w] move container to mark $stack_mark" >/dev/null 2>/dev/null || true
  done

  i3-msg "[con_id=$focused] mark $master_mark" >/dev/null
fi

# Stack should be the left (first) child of the pair, master the right
# (second) one. Swap if not.
first_mark=$(i3-msg -t get_tree | jq -r --arg m "$master_mark" --arg s "$stack_mark" '
  [.. | objects | select(.nodes? != null and (.nodes|length) > 0)
   | select(([.nodes[].marks[]?] | index($m)) != null
            and ([.nodes[].marks[]?] | index($s)) != null)
   | .nodes[0].marks[0]?
  ] | first // empty')
if [ "$first_mark" = "$master_mark" ]; then
  i3-msg "[con_mark=$master_mark] swap container with mark $stack_mark" >/dev/null
fi

# Master gets 65%, stack keeps the remaining part.
i3-msg "[con_mark=$master_mark] resize set 65 ppt" >/dev/null

# Return focus to master.
i3-msg "[con_mark=$master_mark] focus" >/dev/null
