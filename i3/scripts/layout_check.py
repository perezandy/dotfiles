import i3ipc

'''




'''

def get_layout(container):
    layout = container.layout if container else None
    return layout

def print_current_layout(i3):
    focused = i3.get_tree().find_focused()
    parent = focused.parent if focused else None
    layout = get_layout(parent)
    if layout:
        print(layout, flush=True)

def on_window_event(i3, e):
    # Only refresh if layout-affecting events happen
    if e.change in ("focus", "move"):
        print_current_layout(i3)

def on_binding_event(i3, e):
    # If the user changes layout via a keybinding, update
    print_current_layout(i3)

if __name__ == "__main__":
    i3 = i3ipc.Connection()

    # Print the current layout once at start
    print_current_layout(i3)

    # Subscribe to relevant events
    i3.on("window", on_window_event)
    i3.on("binding", on_binding_event)

    # Enter the event loop (blocking, no polling)
    i3.main()

