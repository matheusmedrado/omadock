import QtQuick
import Quickshell.Hyprland

Item {
    id: root

    property var screen
    property var configService
    property var appService
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

    DockSurface {
        id: surface
        screen: root.screen
        items: root.appService ? root.appService.items : []
        configuration: root.configuration
        appService: root.appService
        configService: root.configService
        monitorName: root.monitorName
        requestedVisible: root.monitorEnabled
    }
}
