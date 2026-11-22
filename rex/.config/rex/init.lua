-- Focus adjacent Rex panes without replacing the built-in shortcuts.
rex.bind("ctrl+b>left",  "pane.focus.left")
rex.bind("ctrl+b>right", "pane.focus.right")
rex.bind("ctrl+b>up",    "pane.focus.up")
rex.bind("ctrl+b>down",  "pane.focus.down")

-- tmux splits: % opens a pane on the right; " opens one below (US layout).
rex.bind("ctrl+b>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+b>shift+'", "pane.split", { direction = "down" })

-- A single Ctrl+B now starts a Rex sequence; send one through to nested tmux.
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
