import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services as Services
import "../colors" as ColorsModule
import qs.Core
import QtQuick.Layouts

Item {
    id: root

    visible: Services.Osd.visible
    property var colors: ColorsModule.Colors

    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: Services.Osd.visible ? 60 : -implicitHeight

    implicitWidth: 360
    implicitHeight: 96

    opacity: Services.Osd.visible ? 1.0 : 0.0
    scale: Services.Osd.visible ? 1.0 : 0.96

    Behavior on opacity {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    Behavior on scale {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: 18

        color: Qt.rgba(40/255, 42/255, 54/255, 0.88)

        border.width: 1
        border.color: Qt.rgba(98/255, 114/255, 164/255, 0.25)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Rectangle {
                width: 48
                height: 48
                radius: 12

                color: Qt.rgba(189/255, 147/255, 249/255, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: Services.Osd.type === "volume" ? getVolumeIcon() : Icons.brightness
                    font.pixelSize: 26
                    font.family: "Material Design Icons"
                    color: "#F8F8F2"
                }
            }

            // TEXT COLUMN
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: Services.Osd.type === "volume" ? "Volume" : "Brightness"
                        color: "#F8F8F2"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    Text {
                        text: Math.min(Math.round(Services.Osd.value), 100) + "%"
                        color: Qt.rgba(248/255, 248/255, 242/255, 0.75)
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4

                    color: Qt.rgba(255, 255, 255, 0.06)

                    Rectangle {
                        height: parent.height
                        radius: parent.radius

                        width: parent.width *
                               Math.min(Math.max(Services.Osd.value, 0), 100) / 100

                        color: "#BD93F9"

                        Behavior on width {
                            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }

    function getVolumeIcon() {
        let vol = Services.Osd.value

        if (Services.Audio && Services.Audio.muted)
            return Icons.volumeMuted

        if (vol === 0)
            return Icons.volumeZero
        if (vol < 33)
            return Icons.volumeLow
        if (vol < 66)
            return Icons.volumeMedium

        return Icons.volumeHigh
    }
}
