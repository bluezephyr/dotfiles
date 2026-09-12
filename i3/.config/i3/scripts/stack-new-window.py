#!/usr/bin/env python3
"""Send a newly created window straight into the stack of an active
master-stack layout (see master-stack.py), instead of leaving it beside
master. Triggered by a for_window rule in the i3 config that marks each
new window "__i3_newwin" before invoking this script, so the new window
is identified directly rather than by (unreliable) current focus.
No-op if the workspace has no active master-stack layout.
"""

from i3_layout import connect, focused_workspace_con, mark_names, find_mark, TILED

NEW_WIN_MARK = "__i3_newwin"


def main():
    i3 = connect()
    tree = i3.get_tree()

    new_win = find_mark(tree, NEW_WIN_MARK)
    if new_win is None:
        return
    i3.command(f"[con_mark={NEW_WIN_MARK}] unmark {NEW_WIN_MARK}")

    if new_win.floating not in TILED:
        return

    ws = focused_workspace_con(i3, tree)
    if ws is None:
        return
    master_mark, stack_mark, _pair_mark = mark_names(ws.name)

    # Only act if a master-stack layout already exists here. Deliberately
    # not checking master's exact position: a manual "split" on the
    # focused master nests it one level deeper without moving or
    # unmarking it, and routing must keep working regardless.
    master_con = find_mark(tree, master_mark)
    stack_con = find_mark(tree, stack_mark)
    if master_con is None or stack_con is None:
        return

    if new_win.id == master_con.id:
        return

    # Already a stack member (shouldn't happen for a brand-new window,
    # but "move to mark" errors on a no-op move).
    if any(c.id == new_win.id for c in stack_con.nodes):
        return

    i3.command(f"[con_id={new_win.id}] move container to mark {stack_mark}")


if __name__ == "__main__":
    main()
