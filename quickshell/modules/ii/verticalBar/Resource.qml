import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    implicitHeight: resourceProgress.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    property bool warning: percentage * 100 >= warningThreshold

    Item {
        anchors.centerIn: parent
        implicitWidth: resourceProgress.implicitWidth
        implicitHeight: resourceProgress.implicitHeight

        ClippedFilledCircularProgress {
            id: resourceProgress
            anchors.fill: parent
            value: percentage
            enableAnimation: false
            colPrimary:   root.warning ? Appearance.colors.colError : Appearance.colors.colPrimary
            colSecondary: root.warning ? ColorUtils.transparentize(Appearance.colors.colError, 0.5) : Appearance.m3colors.m3secondaryContainer
            accountForLightBleeding: !root.warning
            Item { width: resourceProgress.implicitWidth; height: resourceProgress.implicitHeight }
        }

        MaterialSymbol {
            anchors.centerIn: parent
            font.weight: Font.Medium
            fill: 1
            text: root.iconName
            iconSize: 13
            color: Appearance.m3colors.m3onPrimary
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.visible
    }
}
