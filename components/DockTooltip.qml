import QtQuick
import Quickshell
import qs.Commons

PopupWindow {
    id: root

    property Item targetItem
    property var targetWindow
    property string label: ""
    // Vertical gap between the tooltip and the item it points at. The item sits
    // inside the dock's content padding, so without this the tooltip lands on
    // the surface rather than above it.
    property int clearance: 0

    visible: false
    color: "transparent"
    implicitWidth: tooltipText.implicitWidth + Style.space(16)
    implicitHeight: tooltipText.implicitHeight + Style.space(10)

    anchor.window: root.targetWindow
    anchor.rect.x: {
        if (!root.targetItem || !root.targetWindow || !root.targetWindow.contentItem
                || !root.targetWindow.backingWindowVisible) return 0
        return root.targetWindow.contentItem.mapFromItem(
            root.targetItem, root.targetItem.width / 2, 0
        ).x - width / 2
    }
    anchor.rect.y: {
        if (!root.targetItem || !root.targetWindow || !root.targetWindow.contentItem
                || !root.targetWindow.backingWindowVisible) return 0
        return root.targetWindow.contentItem.mapFromItem(root.targetItem, 0, 0).y
            - height - root.clearance
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 6) : 0
        color: Color.tooltip.background
        border.color: Color.tooltip.border
        border.width: 1

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.label
            color: Color.tooltip.text
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
        }
    }
}
