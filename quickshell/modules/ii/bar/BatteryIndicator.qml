import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100

    implicitWidth: batteryProgress.implicitWidth
    implicitHeight: Appearance.sizes.barHeight

    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ClippedProgressBar {
        id: batteryProgress
        anchors.centerIn: parent
        value: percentage
        highlightColor: (isLow && !isCharging) ? Appearance.m3colors.m3error : Appearance.colors.colPrimary
        // Empty mask — disables the cutout, text rendered as visible overlay below
        Item {
            width: batteryProgress.valueBarWidth
            height: batteryProgress.valueBarHeight
        }
    }

    RowLayout {
        anchors.centerIn: batteryProgress
        spacing: 0

        MaterialSymbol {
            id: boltIcon
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: -2
            Layout.rightMargin: -2
            fill: 1
            text: "bolt"
            iconSize: Appearance.font.pixelSize.smaller
            visible: isCharging && percentage < 1
            color: Appearance.m3colors.m3onPrimary
        }
        StyledText {
            Layout.alignment: Qt.AlignVCenter
            font: batteryProgress.font
            text: batteryProgress.text
            color: Appearance.m3colors.m3onPrimary
        }
    }

    BatteryPopup {
        id: batteryPopup
        hoverTarget: root
    }
}
