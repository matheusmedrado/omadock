import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "../models/DockModel.js" as DockModel

PanelWindow {
    id: root

    property var items: []
    property var configuration: ({})
    property var appService
    property bool requestedVisible: true

    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int edgeMargin: metrics.edgeMargin
    readonly property int surfaceHeight: dockContent.implicitHeight + edgeMargin

    visible: root.requestedVisible && !remapGuard.remapping
    color: "transparent"
    implicitHeight: surfaceHeight
    aboveWindows: true
    focusable: false
    exclusionMode: ExclusionMode.Ignore
    surfaceFormat.opaque: false
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {
        item: dockContent
    }

    anchors {
        left: true
        right: true
        bottom: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "omadock-surface"

    ScreenMoveRemap {
        id: remapGuard
        window: root
    }

    DockContent {
        id: dockContent
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.edgeMargin
        items: root.items
        configuration: root.configuration
        appService: root.appService
        dockWindow: root
    }
}
