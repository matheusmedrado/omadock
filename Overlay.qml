import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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

    // A dock the user has switched off. The plugin stays loaded and the bar
    // widget stays on the bar -- that is the whole point of the setting -- so
    // what this gates is the dock's surfaces and its window tracking, not the
    // plugin. Anything but an explicit `false` is a dock, so a configuration
    // written before the setting existed keeps the one it already had.
    readonly property bool dockEnabled: {
        var current = configServiceObject.settings
        return !current || current.enabled !== false
    }

    // Bind these to a key to reach the dock without the pointer. A reveal is a
    // latch, not a hover: it holds the dock open on top of whatever Smart Hide
    // would otherwise do, until something conceals it again.
    //
    // IPC requires every declared argument, so the monitor cannot simply be
    // optional -- `reveal` would refuse a bare call. The bare forms act on the
    // focused monitor and the `-On` forms name one, which keeps a keybinding to
    // a single word. Calls are forwarded to root explicitly; an unqualified
    // `toggle()` here would resolve to this handler's own function and recurse.
    IpcHandler {
        target: "omadock"

        // A dock that is switched off refuses the latch rather than setting it
        // against nothing: the latch outlives the state machine, so a reveal
        // taken while there is no dock would bring one back already open, over
        // whatever Smart Hide would have decided for it. Answering `disabled`
        // rather than `ok` also gives a keybinding somewhere to say why nothing
        // happened. Concealing needs no guard -- a dock that is off is as
        // concealed as it gets -- and dropping the latch is worth doing anyway.
        function reveal(): string {
            if (!root.dockEnabled) return "disabled"
            root.open("")
            return "ok"
        }

        function revealOn(monitor: string): string {
            if (!root.dockEnabled) return "disabled"
            root.open(monitor)
            return "ok"
        }

        function conceal(): string {
            root.close()
            return "ok"
        }

        function toggle(): string {
            if (!root.dockEnabled) return "disabled"
            root.toggle("")
            return "ok"
        }

        function toggleOn(monitor: string): string {
            if (!root.dockEnabled) return "disabled"
            root.toggle(monitor)
            return "ok"
        }

        // Switching the dock off keeps the plugin installed and the bar widget
        // on the bar; it is the same setting the first row of the preferences
        // panel writes. `toggle` above is the reveal latch, which is a different
        // thing entirely, so this one is named so that a keybinding cannot
        // confuse the two.
        function enable(): string {
            return root.setEnabled(true)
        }

        function disable(): string {
            return root.setEnabled(false)
        }

        function toggleEnabled(): string {
            return root.setEnabled(!root.dockEnabled)
        }

        function status(): string {
            return root.status()
        }
    }

    ConfigService {
        id: configServiceObject
    }

    WindowService {
        id: windowServiceObject
        active: root.dockEnabled
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
                dockEnabled: root.dockEnabled
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

    function setEnabled(value) {
        return configServiceObject.setValue("enabled", !!value) ? "ok" : "error"
    }

    function status() {
        var states = []
        for (var index = 0; index < dockInstances.length; index += 1) {
            states.push(dockInstances[index].runtimeStatus())
        }
        return "ready enabled=" + dockEnabled + " forcedReveal=" + forcedReveal
            + " monitor=" + forcedMonitorName + " docks=" + JSON.stringify(states)
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

    // Drop a held reveal on the way out rather than on the way back in. A dock
    // switched off while it was latched open would otherwise return open, and
    // clearing it here rather than in the IPC handler means switching the dock
    // off from the panel or by editing config.json does the same thing.
    onDockEnabledChanged: if (!root.dockEnabled) root.close()
}
