import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int effectiveActiveWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    readonly property bool isMonitorFocused: Hyprland.focusedMonitor === root.monitor

    // Dynamic list of workspace IDs visible on this monitor's bar.
    // Includes all occupied workspaces on this monitor plus the currently active one.
    // Empty+unfocused workspaces are evicted automatically (Hyprland removes them from its list).
    property var monitorWorkspaceIds: []
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    readonly property int workspaceIndexInGroup: {
        var idx = monitorWorkspaceIds.indexOf(effectiveActiveWorkspaceId);
        return idx >= 0 ? idx : 0;
    }

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() {
            showNumbersTimer.stop()
        }
    }

    function updateMonitorWorkspaces() {
        var thisMonitor = root.monitor;
        if (!thisMonitor) {
            monitorWorkspaceIds = [];
            workspaceOccupied = [];
            return;
        }

        var ids = new Set();
        var wsValues = Hyprland.workspaces.values;
        for (var i = 0; i < wsValues.length; i++) {
            var ws = wsValues[i];
            if (ws.monitor && ws.monitor.name === thisMonitor.name) {
                ids.add(ws.id);
            }
        }
        // Safety net: always include the active workspace even if empty
        var activeWsId = thisMonitor.activeWorkspace?.id;
        if (activeWsId) ids.add(activeWsId);

        monitorWorkspaceIds = Array.from(ids).sort(function(a, b) { return a - b; });
        updateWorkspaceOccupied();
    }

    function updateWorkspaceOccupied() {
        var wsIdSet = new Set();
        var wsValues = Hyprland.workspaces.values;
        for (var i = 0; i < wsValues.length; i++) wsIdSet.add(wsValues[i].id);
        workspaceOccupied = monitorWorkspaceIds.map(function(id) { return wsIdSet.has(id); });
    }

    Component.onCompleted: updateMonitorWorkspaces()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { updateMonitorWorkspaces(); }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { updateMonitorWorkspaces(); }
    }
    Connections {
        target: root.monitor
        function onActiveWorkspaceChanged() { updateMonitorWorkspaces(); }
    }

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (root.workspaceButtonWidth * Math.max(1, root.monitorWorkspaceIds.length))
    implicitHeight: root.vertical ? (root.workspaceButtonWidth * Math.max(1, root.monitorWorkspaceIds.length)) : Appearance.sizes.barHeight

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }
    Behavior on implicitHeight {
        animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            }
        }
    }

    // Workspaces - background
    Grid {
        z: 1
        anchors.centerIn: parent

        rowSpacing: 0
        columnSpacing: 0
        columns: root.vertical ? 1 : Math.max(1, root.monitorWorkspaceIds.length)
        rows: root.vertical ? Math.max(1, root.monitorWorkspaceIds.length) : 1

        Repeater {
            model: root.monitorWorkspaceIds.length

            Rectangle {
                z: 1
                implicitWidth: workspaceButtonWidth
                implicitHeight: workspaceButtonWidth
                radius: (width / 2)

                // Whether each adjacent slot's workspace is the active (and possibly empty) one
                property bool prevIsActive: root.isMonitorFocused && index > 0 && root.monitorWorkspaceIds[index - 1] === root.effectiveActiveWorkspaceId
                property bool nextIsActive: root.isMonitorFocused && index < root.monitorWorkspaceIds.length - 1 && root.monitorWorkspaceIds[index + 1] === root.effectiveActiveWorkspaceId
                property bool thisIsActive: root.isMonitorFocused && root.monitorWorkspaceIds[index] === root.effectiveActiveWorkspaceId

                property var previousOccupied: index > 0 && (workspaceOccupied[index - 1] && !(!activeWindow?.activated && prevIsActive))
                property var rightOccupied: index < root.monitorWorkspaceIds.length - 1 && (workspaceOccupied[index + 1] && !(!activeWindow?.activated && nextIsActive))
                property var radiusPrev: previousOccupied ? 0 : (width / 2)
                property var radiusNext: rightOccupied ? 0 : (width / 2)

                topLeftRadius: radiusPrev
                bottomLeftRadius: root.vertical ? radiusNext : radiusPrev
                topRightRadius: root.vertical ? radiusPrev : radiusNext
                bottomRightRadius: radiusNext

                color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && thisIsActive)) ? 1 : 0

                Behavior on opacity {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusPrev {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
                Behavior on radiusNext {
                    animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
                }
            }
        }
    }

    // Active workspace indicator — hidden when this monitor is not focused
    Rectangle {
        z: 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary
        opacity: root.isMonitorFocused ? 1 : 0

        anchors {
            verticalCenter: vertical ? undefined : parent.verticalCenter
            horizontalCenter: vertical ? parent.horizontalCenter : undefined
        }

        AnimatedTabIndexPair {
            id: idxPair
            index: root.workspaceIndexInGroup
        }
        property real indicatorPosition: Math.min(idxPair.idx1, idxPair.idx2) * workspaceButtonWidth + root.activeWorkspaceMargin
        property real indicatorLength: Math.abs(idxPair.idx1 - idxPair.idx2) * workspaceButtonWidth + workspaceButtonWidth - root.activeWorkspaceMargin * 2
        property real indicatorThickness: workspaceButtonWidth - root.activeWorkspaceMargin * 2

        x: root.vertical ? null : indicatorPosition
        implicitWidth: root.vertical ? indicatorThickness : indicatorLength
        y: root.vertical ? indicatorPosition : null
        implicitHeight: root.vertical ? indicatorLength : indicatorThickness

        Behavior on opacity {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
    }

    // Workspaces - numbers/icons
    Grid {
        z: 3

        columns: root.vertical ? 1 : Math.max(1, root.monitorWorkspaceIds.length)
        rows: root.vertical ? Math.max(1, root.monitorWorkspaceIds.length) : 1
        columnSpacing: 0
        rowSpacing: 0

        anchors.fill: parent

        Repeater {
            model: root.monitorWorkspaceIds.length

            Button {
                id: button
                property int workspaceValue: root.monitorWorkspaceIds[index] ?? 0
                property bool isActiveOnFocusedMonitor: root.isMonitorFocused && root.effectiveActiveWorkspaceId === workspaceValue
                implicitHeight: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.barHeight
                implicitWidth: vertical ? Appearance.sizes.verticalBarWidth : Appearance.sizes.verticalBarWidth
                onPressed: Hyprland.dispatch(`workspace ${workspaceValue}`)
                width: vertical ? undefined : workspaceButtonWidth
                height: vertical ? workspaceButtonWidth : undefined

                background: Item {
                    id: workspaceButtonBackground
                    implicitWidth: workspaceButtonWidth
                    implicitHeight: workspaceButtonWidth
                    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(button.workspaceValue)
                    property var mainAppIconSource: Quickshell.iconPath(AppSearch.guessIcon(biggestWindow?.class), "image-missing")

                    StyledText { // Workspace number text
                        opacity: root.showNumbers
                            || ((Config.options?.bar.workspaces.alwaysShowNumbers && (!Config.options?.bar.workspaces.showAppIcons || !workspaceButtonBackground.biggestWindow || root.showNumbers))
                            || (root.showNumbers && !Config.options?.bar.workspaces.showAppIcons)
                            )  ? 1 : 0
                        z: 3

                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font {
                            pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                            family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                        }
                        text: Config.options?.bar.workspaces.numberMap[button.workspaceValue - 1] || button.workspaceValue
                        elide: Text.ElideRight
                        color: button.isActiveOnFocusedMonitor ?
                            Appearance.m3colors.m3onPrimary :
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer :
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Rectangle { // Dot instead of ws number
                        id: wsDot
                        opacity: (Config.options?.bar.workspaces.alwaysShowNumbers
                            || root.showNumbers
                            || (Config.options?.bar.workspaces.showAppIcons && workspaceButtonBackground.biggestWindow)
                            ) ? 0 : 1
                        visible: opacity > 0
                        anchors.centerIn: parent
                        width: workspaceButtonWidth * 0.18
                        height: width
                        radius: width / 2
                        color: button.isActiveOnFocusedMonitor ?
                            Appearance.m3colors.m3onPrimary :
                            (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer :
                                Appearance.colors.colOnLayer1Inactive)

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                    }
                    Item { // Main app icon
                        anchors.centerIn: parent
                        width: workspaceButtonWidth
                        height: workspaceButtonWidth
                        opacity: !Config.options?.bar.workspaces.showAppIcons ? 0 :
                            (workspaceButtonBackground.biggestWindow && !root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ?
                            1 : workspaceButtonBackground.biggestWindow ? workspaceIconOpacityShrinked : 0
                            visible: opacity > 0
                        IconImage {
                            id: mainAppIcon
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ?
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked
                            anchors.rightMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ?
                                (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked

                            source: workspaceButtonBackground.mainAppIconSource
                            implicitSize: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? workspaceIconSize : workspaceIconSizeShrinked

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on anchors.rightMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Behavior on implicitSize {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }

                        Loader {
                            active: Config.options.bar.workspaces.monochromeIcons
                            anchors.fill: mainAppIcon
                            sourceComponent: Item {
                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false // There's already color overlay
                                    anchors.fill: parent
                                    source: mainAppIcon
                                    desaturation: 0.8
                                }
                                ColorOverlay {
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(wsDot.color, 0.9)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
