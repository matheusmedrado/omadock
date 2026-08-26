import QtQuick
import Quickshell.Hyprland
import "../services"

Item {
    id: root

    property var screen
    property var configService
    property var appService
    property bool forcedReveal: false
    readonly property string monitorName: monitor ? String(monitor.name || "") : ""
    readonly property var configuration: configService ? configService.settings : ({})
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property bool monitorEnabled: isMonitorEnabled()

    function isMonitorEnabled() {
        var mode = configuration.monitorMode || "all"
        if (mode === "all") return true
        if (!monitor) return false
        if (mode === "focused") {
            return Hyprland.focusedMonitor && Hyprland.focusedMonitor.name === monitor.name
        }
        if (mode === "named") {
            var names = Array.isArray(configuration.monitors) ? configuration.monitors : []
            return names.indexOf(String(monitor.name || "")) >= 0
        }
        return true
    }

    HideController {
        id: hideController
        configuration: root.configuration
        monitor: root.monitor
        windowService: root.appService ? root.appService.windowService : null
        dockSurface: surface
        monitorEnabled: root.monitorEnabled
        forcedReveal: root.forcedReveal
    }

    EdgeSensor {
        id: edgeSensor
        screen: root.screen
        hideController: hideController
        requestedVisible: root.monitorEnabled
        edgeEnabled: hideController.edgeEnabled
    }

    DockSurface {
        id: surface
        screen: root.screen
        items: root.appService ? root.appService.items : []
        configuration: root.configuration
        appService: root.appService
        configService: root.configService
        monitorName: root.monitorName
        hideController: hideController
        revealProgress: hideController.revealProgress
        requestedVisible: root.monitorEnabled
    }
}
