pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

// GitHub contributions-style grid for the current month.
Item {
    id: root

    required property color colText

    readonly property int    cellSize:     11
    readonly property int    cellGap:      2
    readonly property int    cellStep:     cellSize + cellGap
    readonly property int    padding:      10
    readonly property int    today:        new Date().getDate()
    readonly property int    currentMonth: new Date().getMonth() + 1
    readonly property string monthPad:    String(currentMonth).padStart(2, '0')

    // Dracula palette
    readonly property color draculaBg:     "#282a36"
    readonly property list<color> draculaPurple: [
        "#44385a",  // level 1 — 1 commit
        "#7c5cbf",  // level 2 — 2–3 commits
        "#bd93f9",  // level 3 — 4+ commits
    ]
    readonly property color grayColor:    "#44475a"  // past day, 0 commits
    readonly property color borderColor:  "#6272a4"  // future day outline
    readonly property color labelColor:   "#f8f8f2"  // Dracula foreground

    function commitColor(count) {
        if (count >= 4) return draculaPurple[2];
        if (count >= 2) return draculaPurple[1];
        return draculaPurple[0];
    }

    // First weekday of the month (0 = Mon … 6 = Sun)
    readonly property int monthStartOffset: {
        const d = new Date();
        const first = new Date(d.getFullYear(), d.getMonth(), 1);
        return (first.getDay() + 6) % 7;
    }

    readonly property int daysInMonth: GithubCommits.daysInMonth
    readonly property int totalCells:  monthStartOffset + daysInMonth
    readonly property int weekColumns: 7
    readonly property int rowCount:    Math.ceil(totalCells / weekColumns)

    readonly property list<string> dowLabels: ["M", "T", "W", "T", "F", "S", "S"]

    readonly property int gridWidth:  weekColumns * cellStep - cellGap
    readonly property int gridHeight: headerRow.implicitHeight + 3 + rowCount * cellStep - cellGap

    implicitWidth:  gridWidth  + padding * 2
    implicitHeight: gridHeight + padding * 2

    // Background card
    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: root.draculaBg
        opacity: 0.82
    }

    // Day-of-week header
    Row {
        id: headerRow
        anchors {
            top:  parent.top
            left: parent.left
            topMargin:  root.padding
            leftMargin: root.padding
        }
        spacing: root.cellGap

        Repeater {
            model: root.dowLabels
            delegate: Item {
                required property string modelData
                width: root.cellSize
                height: dowLabel.implicitHeight

                StyledText {
                    id: dowLabel
                    anchors.centerIn: parent
                    text: parent.modelData
                    font.pixelSize: 8
                    color: root.labelColor
                    opacity: 0.45
                }
            }
        }
    }

    // Cell grid
    Grid {
        anchors {
            top:  headerRow.bottom
            left: parent.left
            topMargin:  3
            leftMargin: root.padding
        }
        columns:       root.weekColumns
        rowSpacing:    root.cellGap
        columnSpacing: root.cellGap

        Repeater {
            model: root.rowCount * root.weekColumns
            delegate: Item {
                id: cell
                required property int index

                readonly property int  dayNumber:     index - root.monthStartOffset + 1
                readonly property bool isActive:      dayNumber >= 1 && dayNumber <= root.daysInMonth
                readonly property bool isFuture:      isActive && dayNumber > root.today
                readonly property bool isPastOrToday: isActive && dayNumber <= root.today
                readonly property int  commitCount:   isActive ? root.countForDay(dayNumber) : 0
                readonly property bool hasCommits:    commitCount > 0

                width:  root.cellSize
                height: root.cellSize

                // Past/today with commits — filled purple
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    visible: cell.isPastOrToday && cell.hasCommits
                    color: root.commitColor(cell.commitCount)
                    Behavior on color {
                        ColorAnimation { duration: 400 }
                    }
                }

                // Past/today with 0 commits — solid gray
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    visible: cell.isPastOrToday && !cell.hasCommits
                    color: root.grayColor
                }

                // Future days — outline only
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    visible: cell.isFuture
                    color: "transparent"
                    border.color: root.borderColor
                    border.width: 1
                    opacity: 0.5
                }

                HoverHandler { id: cellHover }
                StyledToolTip {
                    visible: cellHover.hovered && cell.isActive
                    text: {
                        const d    = cell.dayNumber;
                        const c    = cell.commitCount;
                        const date = root.monthPad + "/" + String(d).padStart(2, '0');
                        if (cell.isFuture) return date;
                        return Translation.tr("%1 · %2 commit(s)").arg(date).arg(c);
                    }
                }
            }
        }
    }

    function countForDay(day) {
        const entry = GithubCommits.dailyCommits[day - 1];
        return entry ? entry.count : 0;
    }
}
