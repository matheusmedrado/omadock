import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Ui

PanelWindow {
    id: root

    property var hideController
    property bool requestedVisible: true
    property bool edgeEnabled: false

    visible: root.requestedVisible && root.edgeEnabled && !remapGuard.remapping
    color: "transparent"
    implicitHeight: 2
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "omadock-edge"

    anchors {
        left: true
        right: true
        bottom: true
    }

    ScreenMoveRemap {
        id: remapGuard
        window: root
    }

    Region {
        id: sensorRegion
        item: sensor
    }
    mask: sensorRegion

    Rectangle {
        id: sensor
        anchors.fill: parent
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onEntered: if (root.hideController) root.hideController.edgeHovered = true
            onExited: if (root.hideController) root.hideController.edgeHovered = false
        }
    }

    Component.onDestruction: {
        if (root.hideController) root.hideController.edgeHovered = false
    }
}
