#!/usr/bin/env python3
"""i3 master-stack layout
Focused window -> master (right, 65%)
All others -> vertical stack on the left
Runs repeatedly to promote new masters.

Maintains an explicit, marked three-container tree:
  pair (splith)
    +-- stack (splitv, all non-focused windows)
    +-- master (focused window)

The pair/stack containers are reused across runs (windows are moved in
and out via "move container to mark", see i3_layout.group_into_container)
rather than rebuilt from scratch each time. If no valid structure exists
yet (first run, or the master window closed), it's (re)built.
"""

from i3_layout import (
    connect,
    focused_workspace_con,
    tiled_windows,
    mark_names,
    find_mark,
    group_into_container,
)

MASTER_PERCENT = 65


def main():
    i3 = connect()
    tree = i3.get_tree()

    ws = focused_workspace_con(i3, tree)
    if ws is None:
        return

    windows = tiled_windows(ws)
    if len(windows) < 2:
        return

    focused = ws.find_focused()
    if focused is None or focused.floating not in ("auto_off", "user_off"):
        return

    others = [w for w in windows if w.id != focused.id]

    master_mark, stack_mark, pair_mark = mark_names(ws.name)

    # Valid existing structure: pair, stack and master marks each exist.
    # Deliberately not requiring master to be a *direct* child of the
    # pair: an unrelated manual "split" on the focused master nests it
    # one level deeper without moving or unmarking it, and that shouldn't
    # force a full rebuild -- the reuse path below re-parents master
    # properly again as soon as focus moves off of it.
    pair_con = find_mark(tree, pair_mark)
    master_con = find_mark(tree, master_mark)
    stack_con = find_mark(tree, stack_mark)
    valid = pair_con is not None and master_con is not None and stack_con is not None

    if valid:
        old_master_id = master_con.id
        stack_children = {c.id for c in stack_con.nodes}
        pair_children = {c.id for c in pair_con.nodes}

        # Drain every non-focused window into the stack (also picks up
        # windows that appeared since the last run and aren't part of
        # the stack yet).
        for w in others:
            if w.id in stack_children:
                continue
            i3.command(f"[con_id={w.id}] move container to mark {stack_mark}")

        if focused.id != old_master_id:
            i3.command(f"[con_mark={master_mark}] unmark {master_mark}")
            if focused.id not in pair_children:
                i3.command(f"[con_id={focused.id}] move container to mark {pair_mark}")
            i3.command(f"[con_id={focused.id}] mark {master_mark}")
    else:
        # No valid pair: rebuild it, reusing the stack container if one
        # still exists (grouping the whole stack container together with
        # master, rather than one of the stack's leaves, avoids leaving
        # an orphaned wrapper behind).
        i3.command(f"[con_mark={master_mark}] unmark {master_mark}")
        i3.command(f"[con_mark={pair_mark}] unmark {pair_mark}")

        tree = i3.get_tree()
        stack_con = find_mark(tree, stack_mark)

        if stack_con is None:
            i3.command(f"[con_mark={stack_mark}] unmark {stack_mark}")
            group_into_container(i3, stack_mark, "v", [w.id for w in others])
        else:
            for w in others:
                i3.command(f"[con_id={w.id}] move container to mark {stack_mark}")

        tree = i3.get_tree()
        stack_con = find_mark(tree, stack_mark)
        group_into_container(i3, pair_mark, "h", [stack_con.id, focused.id])
        i3.command(f"[con_id={focused.id}] mark {master_mark}")

    # Stack should be the left (first) child of the pair, master the
    # right (second) one. Swap if not -- "swap container with mark"
    # exchanges two containers' tree positions outright, so it's a safe
    # fix regardless of why the order came out wrong.
    tree = i3.get_tree()
    pair_con = find_mark(tree, pair_mark)
    if pair_con and pair_con.nodes:
        first_child_marks = pair_con.nodes[0].marks
        if master_mark in first_child_marks:
            i3.command(f"[con_mark={master_mark}] swap container with mark {stack_mark}")

    # Master gets 65%, stack keeps the remaining part.
    i3.command(f"[con_mark={master_mark}] resize set {MASTER_PERCENT} ppt")

    # Return focus to master.
    i3.command(f"[con_mark={master_mark}] focus")


if __name__ == "__main__":
    main()
