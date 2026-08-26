import QtQuick
import Quickshell
import Quickshell.Hyprland
import "components"
import "services"

Item {
    id: root

    property var shell
    property var manifest
    property var pluginRegistry
    property string omarchyPath: ""
    property bool forcedReveal: false
    property string forcedMonitorName: ""
    property var dockInstances: []
    property alias dockConfigService: configServiceObject
    property alias dockAppService: appService

    ConfigService {
        id: configServiceObject
    }

    WindowService {
        id: windowServiceObject
    }

    AppService {
        id: appService
        configService: configServiceObject
        windowService: windowServiceObject
        shell: root.shell
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            DockInstance {
                id: dockInstance
                required property var modelData
                screen: modelData
                configService: root.dockConfigService
                appService: root.dockAppService
                forcedReveal: root.forcedReveal
                    && (!root.forcedMonitorName || root.forcedMonitorName === dockInstance.monitorName)

                Component.onCompleted: root.registerDockInstance(dockInstance)
                Component.onDestruction: root.unregisterDockInstance(dockInstance)
            }
        }
    }

    function monitorNameFromPayload(payload) {
        var requested = payload
        if (payload && typeof payload === "object") {
            requested = payload.monitorName !== undefined ? payload.monitorName
                : payload.monitor !== undefined ? payload.monitor : payload.output
        }
        if (requested && typeof requested === "object") requested = requested.name
        if (requested) return String(requested)

        var focused = Hyprland.focusedMonitor
        return focused && focused.name ? String(focused.name) : ""
    }

    function open(payload) {
        forcedMonitorName = monitorNameFromPayload(payload)
        forcedReveal = true
    }

    function close() {
        forcedReveal = false
        forcedMonitorName = ""
    }

    function toggle(payload) {
        if (forcedReveal) close()
        else open(payload)
    }

    function status() {
        var states = []
        for (var index = 0; index < dockInstances.length; index += 1) {
            states.push(dockInstances[index].runtimeStatus())
        }
        return "ready forcedReveal=" + forcedReveal + " monitor=" + forcedMonitorName
            + " docks=" + JSON.stringify(states)
    }

    function registerDockInstance(instance) {
        var next = dockInstances.slice()
        if (next.indexOf(instance) < 0) next.push(instance)
        dockInstances = next
    }

    function unregisterDockInstance(instance) {
        var next = []
        for (var index = 0; index < dockInstances.length; index += 1) {
            if (dockInstances[index] !== instance) next.push(dockInstances[index])
        }
        dockInstances = next
    }
}
