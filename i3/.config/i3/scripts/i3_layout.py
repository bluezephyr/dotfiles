#!/usr/bin/env python3
"""Shared i3 layout helpers used by master-stack.py, equalize-windows.py,
and stack-new-window.py.

All tree-mutating operations go through a small set of primitives built
on top of i3's marks:

  - A mark on a *leaf* container: "move container to mark X" inserts the
    moved container as a new *sibling* of the marked leaf.
  - A mark on a container *with children*: the same move instead nests
    the moved container as a new *child* of it.

group_into_container() uses this distinction to gather a list of
container ids (windows or whole subtrees) into one, correctly oriented,
container -- the shared operation behind equalize-windows.py's flatten
step and master-stack.py's stack/pair construction.

Re-orienting an *existing* multi-child container in place (via "layout
splith"/"splitv" or "split toggle") isn't reliable in i3 (confirmed
empirically), even while genuinely focused on it. The reliable way to
get a specific orientation is to wrap fresh with "split <h|v>".

Also: "focus parent" is always its own separate command call, never
chained together with "split" in the same i3-msg call. Empirically
(tested against this i3 version), chaining "split v, focus parent,
mark X" in one call leaves the mark on the leaf instead of the new
split container -- issuing them as separate calls is what reliably
marks the container.
"""

import re

from i3ipc import Connection

TILED = ("auto_off", "user_off")


def connect() -> Connection:
    return Connection()


def sanitize(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", name)


def mark_names(ws_name: str):
    """(master_mark, stack_mark, pair_mark) for a workspace name."""
    s = sanitize(ws_name)
    return f"__i3_master_{s}", f"__i3_stack_{s}", f"__i3_pair_{s}"


def focused_workspace_con(i3: Connection, tree=None):
    """The Con for the currently focused workspace, or None."""
    tree = tree or i3.get_tree()
    ws_name = next((w.name for w in i3.get_workspaces() if w.focused), None)
    if ws_name is None:
        return None
    return next((w for w in tree.workspaces() if w.name == ws_name), None)


def tiled_windows(ws):
    """All tiled (non-floating) leaf windows in a workspace, in tree order."""
    return [c for c in ws.leaves() if c.floating in TILED]


def find_mark(tree, mark: str):
    """The single container carrying `mark`, or None."""
    matches = tree.find_marked(f"^{re.escape(mark)}$")
    return matches[0] if matches else None


def group_into_container(i3: Connection, mark: str, orientation: str, ids):
    """Gather `ids` (window or subtree container ids) into one container
    split `orientation` ("h" or "v"), marked `mark`.

    If the first id already has children (an existing subtree, such as a
    stack, to be preserved as one grouped unit) it's always wrapped
    fresh. Otherwise it's a plain leaf: marked directly, with the rest
    drained in as its siblings, wrapping only if the resulting shared
    parent isn't already the right orientation.
    """
    tree = i3.get_tree()
    first = tree.find_by_id(ids[0])
    split_layout = f"split{orientation}"
    first_is_subtree = bool(first.nodes or first.floating_nodes)

    def wrap_first():
        if first_is_subtree:
            # Reach `first` itself (a container, not a leaf) via one of
            # its own leaves plus one "focus parent" hop, then split
            # that -- splitting the leaf directly would only wrap the
            # leaf, nested one level inside `first`, not `first` itself.
            leaf = first.leaves()[0]
            i3.command(f"[con_id={leaf.id}] focus")
            i3.command("focus parent")
        else:
            i3.command(f"[con_id={first.id}] focus")
        i3.command(f"split {orientation}")
        i3.command("focus parent")
        i3.command(f"mark {mark}")

    def drain_rest():
        for cid in ids[1:]:
            i3.command(f"[con_id={cid}] move container to mark {mark}")

    if first_is_subtree:
        wrap_first()
        drain_rest()
        return

    i3.command(f"[con_id={first.id}] mark {mark}")
    drain_rest()

    tree = i3.get_tree()
    marked = find_mark(tree, mark)
    parent = marked.parent if marked else None
    if parent is not None and parent.layout != split_layout:
        wrap_first()
        drain_rest()
