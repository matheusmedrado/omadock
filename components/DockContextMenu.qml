import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "../models/ActionModel.js" as ActionModel

// A full-screen layer surface with the menu card positioned inside it, rather
// than a PopupWindow anchored to the dock.
//
// An anchored PopupWindow renders but receives no pointer input here: no hover,
// no cursor change, and a click on a row counts as a click outside, which
// dismissed the menu without ever running the action. Every interactive popup
// in the Omarchy shell is built this way for the same reason -- see
// Ui/KeyboardPanel -- so the menu follows suit. Clicks outside the card land on
// this surface and dismiss it, which is also what the focus grab used to do.
PanelWindow {
    id: root

    property Item targetItem
    property var targetWindow
    property var itemRecord: ({})
    property var appService
    property var configService
    property bool requestedOpen: false
    signal menuClosed()

    readonly property var actions: ActionModel.actionsForItem(itemRecord)
    readonly property int padding: Style.space(4)
    readonly property int rowHeight: Style.space(28)
    readonly property int cardWidth: Style.space(220)
    readonly property int cardHeight: root.actions.length * root.rowHeight + root.padding * 2

    visible: root.requestedOpen && root.actions.length > 0
    screen: root.targetWindow ? root.targetWindow.screen : null
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "omadock-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    function close() {
        menuClosed()
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

    // Where the card sits, in this surface's coordinates. Measured when the menu
    // opens rather than bound: mapToItem is a one-shot, so as a binding it never
    // re-ran for a different item and, worse, returned 0 whenever it happened to
    // evaluate before the dock's backing window was up -- which pinned every
    // menu to the left edge regardless of which application was clicked.
    property real anchorScreenX: 0
    property real anchorScreenY: 0

    function measureAnchor() {
        if (!root.targetItem || !root.targetWindow) return

        // The dock is a full-width surface pinned to the bottom edge, so a point
        // in its scene is already at the right screen x, and screen y is that
        // point offset by how far the surface sits off the bottom.
        var point = root.targetItem.mapToItem(null, root.targetItem.width / 2, 0)
        var screenHeight = root.screen ? root.screen.height : root.height
        root.anchorScreenX = point.x
        root.anchorScreenY = screenHeight - root.targetWindow.height + point.y
    }

    onRequestedOpenChanged: if (root.requestedOpen) root.measureAnchor()
    onVisibleChanged: if (root.visible) root.measureAnchor()

    // Dismissal. The card sits above this, so only clicks that miss it land here.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: root.close()
    }

    Rectangle {
        id: card

        x: Math.max(Style.space(4),
            Math.min(root.anchorScreenX - width / 2, root.width - width - Style.space(4)))
        y: Math.max(Style.space(4), root.anchorScreenY - height - Style.space(6))
        width: root.cardWidth
        height: root.cardHeight

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
                    id: row
                    required property var modelData
                    width: card.width - root.padding * 2
                    height: root.rowHeight
                    radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 5) : 0
                    // A wash rather than a solid accent fill: a theme's accent is
                    // often darker than its text, which left the highlighted row
                    // harder to read than the rest.
                    color: rowMouse.containsMouse
                        ? Util.alpha(Color.popups.text, 0.12) : "transparent"

                    Text {
                        anchors.fill: parent
                        anchors.leftMargin: Style.space(8)
                        anchors.rightMargin: Style.space(8)
                        text: row.modelData.label
                        color: rowMouse.containsMouse
                            ? Color.popups.text : Util.alpha(Color.popups.text, 0.75)
                        font.family: Style.font.family
                        font.pixelSize: Style.font.body
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.trigger(row.modelData.key)
                    }
                }
            }
        }
    }
}
