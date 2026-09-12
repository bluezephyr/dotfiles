#!/usr/bin/env python3
"""Flatten and equalize all tiled windows in the focused workspace into a
single horizontal row of equal-width windows.

Uses i3_layout.group_into_container to gather every window into one
container (creating or re-orienting it as needed -- see i3_layout.py for
why re-orienting an existing container isn't done in place), then resizes
each window to an equal share.
"""

from i3_layout import connect, focused_workspace_con, tiled_windows, group_into_container

TMP_MARK = "__i3_equalize_tmp"


def main():
    i3 = connect()
    ws = focused_workspace_con(i3)
    if ws is None:
        return

    windows = tiled_windows(ws)
    if len(windows) < 2:
        return

    i3.command(f"[con_mark={TMP_MARK}] unmark {TMP_MARK}")
    group_into_container(i3, TMP_MARK, "h", [w.id for w in windows])
    i3.command(f"[con_mark={TMP_MARK}] unmark {TMP_MARK}")

    share = 100 // len(windows)
    for w in windows:
        i3.command(f"[con_id={w.id}] resize set {share} ppt")


if __name__ == "__main__":
    main()
