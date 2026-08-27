import QtQuick
import Quickshell
import Quickshell.Io
import "../models/ConfigModel.js" as ConfigModel

Item {
    id: root

    property var settings: ConfigModel.defaultConfig()
    property var rawSettings: ({})
    property bool ready: false
    property bool writing: false
    property bool directoryReady: false
    property bool seeded: false
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
            // The watcher sees the file mid-write: shell redirection and most
            // editors truncate before writing, so an empty read is normally a
            // half-finished save rather than an empty configuration. Writing
            // defaults back here would overwrite whatever the user was in the
            // middle of saving, so re-read instead and keep what we have.
            if (!root.ready) applyConfiguration(ConfigModel.defaultConfig(), {})
            rereadTimer.restart()
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
        if (pendingText === null || writing) return
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
        return pinAt(desktopId, Array.isArray(settings.pinned) ? settings.pinned.length : 0)
    }

    function pinAt(desktopId, index) {
        var value = String(desktopId || "").trim()
        if (!value || !ConfigModel.normalizedId(value)) return false

        var next = ConfigModel.clone(settings)
        var pins = Array.isArray(next.pinned) ? next.pinned : []
        var updated = ConfigModel.insertPinned(pins, value, index)
        if (ConfigModel.samePinnedOrder(pins, updated)) return true
        next.pinned = updated
        return save(next)
    }

    function unpin(desktopId) {
        var next = ConfigModel.clone(settings)
        var wanted = ConfigModel.normalizedId(desktopId)
        var remaining = []
        for (var index = 0; index < next.pinned.length; index += 1) {
            if (ConfigModel.normalizedId(next.pinned[index].desktopId) !== wanted) {
                remaining.push(next.pinned[index])
            }
        }
        next.pinned = remaining
        return save(next)
    }

    function reorderPinned(fromIndex, toIndex) {
        var next = ConfigModel.clone(settings)
        var current = Array.isArray(next.pinned) ? next.pinned : []
        var reordered = ConfigModel.reorderPinned(current, fromIndex, toIndex)
        if (reordered === null) return false
        if (ConfigModel.samePinnedOrder(current, reordered)) return true
        next.pinned = reordered
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

        // A load failure on a fresh install means there is no config.json yet.
        // Seed one so the available settings are discoverable, but only once and
        // only while nothing has ever loaded, so a transient read failure cannot
        // overwrite an existing configuration.
        onLoadFailed: {
            root.ensureDirectory()
            if (root.ready || root.seeded) return
            root.seeded = true
            root.applyConfiguration(ConfigModel.defaultConfig(), {})
            root.persist(root.settings, root.rawSettings)
        }

        onFileChanged: {
            if (!root.writing) fileView.reload()
        }

        onSaved: {
            root.writing = false
            root.writePending()
        }
        onSaveFailed: {
            root.writing = false
            root.reportError("could not write config.json; keeping settings in memory")
        }
    }

    // Re-read after an empty or mid-write read settles.
    Timer {
        id: rereadTimer
        interval: 120
        repeat: false
        onTriggered: fileView.reload()
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
