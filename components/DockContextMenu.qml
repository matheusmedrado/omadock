import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Commons
import "../models/ActionModel.js" as ActionModel

PopupWindow {
    id: root

    property Item targetItem
    property var targetWindow
    property var itemRecord: ({})
    property var appService
    property var configService
    property bool requestedOpen: false
    signal closed()

    readonly property var actions: ActionModel.actionsForItem(itemRecord)
    readonly property int padding: Style.space(4)
    readonly property int rowHeight: Style.space(28)

    visible: root.requestedOpen && root.actions.length > 0
    color: "transparent"
    implicitWidth: Style.space(220)
    implicitHeight: root.actions.length * root.rowHeight + root.padding * 2

    anchor.window: root.targetWindow
    anchor.rect.x: {
        if (!root.targetItem || !root.targetWindow || !root.targetWindow.contentItem
                || !root.targetWindow.backingWindowVisible) return 0
        var point = root.targetWindow.contentItem.mapFromItem(
            root.targetItem, root.targetItem.width / 2, 0
        )
        return Math.max(Style.space(4), Math.min(
            point.x - width / 2,
            root.targetWindow.width - width - Style.space(4)
        ))
    }
    anchor.rect.y: {
        if (!root.targetItem || !root.targetWindow || !root.targetWindow.contentItem
                || !root.targetWindow.backingWindowVisible) return 0
        return root.targetWindow.contentItem.mapFromItem(root.targetItem, 0, 0).y
            - height - Style.space(6)
    }

    HyprlandFocusGrab {
        active: root.visible
        windows: root.targetWindow ? [root, root.targetWindow] : [root]
        onCleared: root.close()
    }

    function close() {
        closed()
    }

    function trigger(action) {
        var item = root.itemRecord
        var service = root.appService
        if (!service) {
            root.close()
            return
        }

        if (action === "launch-new") service.launchNew(item)
        else if (action === "focus-next") service.focusNext(item)
        else if (action === "pin" && root.configService) root.configService.pin(item.desktopId)
        else if (action === "unpin" && root.configService) root.configService.unpin(item.desktopId)
        else if (action === "close-active") service.closeActive(item)
        root.close()
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 8) : 0
        color: Color.popups.background
        border.color: Color.popups.border
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 0

            Repeater {
                model: root.actions

                delegate: Rectangle {
                    required property var modelData
                    width: root.width - root.padding * 2
                    height: root.rowHeight
                    color: mouseArea.containsMouse ? Color.accent : "transparent"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Style.space(8)
                        anchors.rightMargin: Style.space(8)
                        text: modelData.label
                        color: mouseArea.containsMouse ? Color.background : Color.popups.text
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.trigger(modelData.key)
                    }
                }
            }
        }
    }
}
