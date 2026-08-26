import QtQml
import Quickshell
import Quickshell.Io
import "../models/ConfigModel.js" as ConfigModel

QtObject {
    id: root

    property var settings: ConfigModel.defaultConfig()
    property var rawSettings: ({})
    property bool ready: false
    property bool writing: false
    property bool directoryReady: false
    property var pendingText: null

    readonly property string configRoot: {
        var xdgConfigHome = Quickshell.env("XDG_CONFIG_HOME")
        if (xdgConfigHome && xdgConfigHome.length > 0) return xdgConfigHome

        var homePath = Quickshell.env("HOME")
        return homePath ? homePath + "/.config" : ""
    }
    readonly property string configDirectory: configRoot + "/omadock"
    readonly property string configPath: configDirectory + "/config.json"

    signal configurationChanged(var configuration)
    signal configurationError(string message)

    function reportError(message) {
        console.warn("OmaDock: " + message)
        configurationError(message)
    }

    function applyConfiguration(configuration, raw) {
        settings = ConfigModel.clone(configuration)
        rawSettings = ConfigModel.clone(raw || configuration)
        ready = true
        configurationChanged(settings)
    }

    function acceptText(text) {
        var parsed
        if (!text || text.trim() === "") {
            applyConfiguration(ConfigModel.defaultConfig(), {})
            persist(settings, rawSettings)
            return
        }

        try {
            parsed = JSON.parse(text)
        } catch (error) {
            reportError("invalid config.json; keeping the last known-good configuration")
            return
        }

        var normalized = ConfigModel.normalizeConfig(parsed)
        if (!normalized.valid) {
            reportError(normalized.errors[0] + "; keeping the last known-good configuration")
            return
        }

        applyConfiguration(normalized.value, parsed)
        if (normalized.warnings.length > 0) {
            console.warn("OmaDock: normalized " + normalized.warnings.length + " config value(s)")
        }
    }

    function load() {
        if (fileView.loaded) acceptText(fileView.text())
        else fileView.reload()
    }

    function ensureDirectory() {
        if (directoryReady) {
            writePending()
            return
        }
        if (!directoryProcess.running) directoryProcess.running = true
    }

    function writePending() {
        if (pendingText === null) return
        writing = true
        fileView.setText(pendingText)
        pendingText = null
    }

    function persist(configuration, original) {
        var payload = ConfigModel.mergeKnownSettings(original, configuration)
        rawSettings = ConfigModel.clone(payload)
        pendingText = JSON.stringify(payload, null, 2) + "\n"
        ensureDirectory()
    }

    function save(candidate) {
        var normalized = ConfigModel.normalizeConfig(candidate)
        if (!normalized.valid) {
            reportError(normalized.errors[0] + "; keeping the last known-good configuration")
            return false
        }

        applyConfiguration(normalized.value, ConfigModel.mergeKnownSettings(rawSettings, normalized.value))
        persist(settings, rawSettings)
        return true
    }

    function pin(desktopId) {
        var next = ConfigModel.clone(settings)
        next.pinned.push({ desktopId: desktopId })
        return save(next)
    }

    function unpin(desktopId) {
        var next = ConfigModel.clone(settings)
        var wanted = String(desktopId || "").trim().toLowerCase()
        var remaining = []
        for (var index = 0; index < next.pinned.length; index += 1) {
            if (String(next.pinned[index].desktopId).trim().toLowerCase() !== wanted) {
                remaining.push(next.pinned[index])
            }
        }
        next.pinned = remaining
        return save(next)
    }

    function reorderPinned(fromIndex, toIndex) {
        var next = ConfigModel.clone(settings)
        if (fromIndex < 0 || fromIndex >= next.pinned.length
                || toIndex < 0 || toIndex >= next.pinned.length) return false

        var moved = next.pinned.splice(fromIndex, 1)[0]
        next.pinned.splice(toIndex, 0, moved)
        return save(next)
    }

    FileView {
        id: fileView
        path: root.configPath
        watchChanges: true
        atomicWrites: true
        printErrors: false

        onLoaded: {
            root.directoryReady = true
            root.acceptText(text())
        }

        onLoadFailed: root.ensureDirectory()

        onFileChanged: {
            if (!root.writing) fileView.reload()
        }

        onSaved: root.writing = false
        onSaveFailed: {
            root.writing = false
            root.reportError("could not write config.json; keeping settings in memory")
        }
    }

    Process {
        id: directoryProcess
        command: ["mkdir", "-p", root.configDirectory]

        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.reportError("could not create the configuration directory")
                return
            }

            root.directoryReady = true
            root.writePending()
        }
    }

    Component.onCompleted: root.load()
}
