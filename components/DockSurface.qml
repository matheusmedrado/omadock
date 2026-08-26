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
    property var configService
    property string monitorName: ""
    property var hideController
    property real revealProgress: 1
    property bool requestedVisible: true

    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int edgeMargin: metrics.edgeMargin
    readonly property int surfaceHeight: dockContent.implicitHeight + edgeMargin
    readonly property real dockWidth: dockContent.width
    readonly property real dockHeight: dockContent.height
    readonly property bool reserveSpace: configuration.behavior
        && configuration.behavior.hideMode === "never"
        && configuration.behavior.reserveSpace === true

    visible: root.requestedVisible && !remapGuard.remapping
    color: "transparent"
    implicitHeight: surfaceHeight
    aboveWindows: true
    focusable: false
    exclusionMode: root.reserveSpace ? ExclusionMode.Auto : ExclusionMode.Ignore
    surfaceFormat.opaque: false
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {
        item: root.revealProgress > 0 ? dockContent : null
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
        y: root.surfaceHeight - root.edgeMargin - height
            + (1 - root.revealProgress) * root.surfaceHeight
        opacity: root.revealProgress <= 0 ? 0 : Math.min(1, root.revealProgress / 0.7)
        items: root.items
        configuration: root.configuration
        appService: root.appService
        configService: root.configService
        monitorName: root.monitorName
        hideController: root.hideController
        dockWindow: root
    }
}
