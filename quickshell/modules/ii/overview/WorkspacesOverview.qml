import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    PanelWindow {
        id: panelWindow
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        visible: GlobalStates.workspacesOpen

        WlrLayershell.namespace: "quickshell:workspaces"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.workspacesOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.workspacesOpen ? overviewWidget : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onWorkspacesOpenChanged() {
                if (!GlobalStates.workspacesOpen) {
                    GlobalFocusGrab.dismiss();
                } else {
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.workspacesOpen = false;
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                GlobalStates.workspacesOpen = false;
            } else if (event.key === Qt.Key_Left) {
                Hyprland.dispatch("workspace r-1");
            } else if (event.key === Qt.Key_Right) {
                Hyprland.dispatch("workspace r+1");
            }
        }

        OverviewWidget {
            id: overviewWidget
            screen: panelWindow.screen
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: Appearance.sizes.elevationMargin
            }
        }
    }

    GlobalShortcut {
        name: "workspacesToggle"
        description: "Toggles standalone workspace overview"

        onPressed: {
            GlobalStates.workspacesOpen = !GlobalStates.workspacesOpen;
        }
    }
}
