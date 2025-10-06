
'''
    This script is meant to fix the editor redraw issues
    seen when using unity and i3 simultaneously.

    It does this by sending a window refresh signal
    to anything in the unity class
'''
from i3ipc import Connection, Event
import time

i3 = Connection()

def on_window_focus(i3, e):

    #TODO: Save previous windows output and workspace. 
    # If it's the same output, but a different workspace,
    # redraw else do nothing.
    if e.container.window_class == "Unity":
        e.container.command("fullscreen toggle")
        time.sleep(0.1)
        e.container.command("fullscreen toggle")
        print("Focused on unity window")
        return
    print("Focused on non-unity window")

i3.on(Event.WINDOW_FOCUS, on_window_focus)

i3.main()
