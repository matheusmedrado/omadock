import QtQuick
import Quickshell
import "../models/AppMatcher.js" as AppMatcher
import "../models/ActionModel.js" as ActionModel

Item {
    id: root

    property var configService
    property var windowService
    property var shell
    property var items: []
    property var desktopEntries: []
    property var desktopIndex: ({})
    property var sequenceByKey: ({})
    property int nextSequence: 0

    signal launchFailed(string desktopId)

    function modelValues(model) {
        return model && model.values ? model.values : []
    }

    function currentConfig() {
        return root.configService && root.configService.settings
            ? root.configService.settings
            : ({ pinned: [], aliases: {}, behavior: { showRunningUnpinned: true } })
    }

    function refreshDesktopEntries() {
        desktopEntries = modelValues(DesktopEntries.applications)
        var index = {}
        for (var entryIndex = 0; entryIndex < desktopEntries.length; entryIndex += 1) {
            var entry = desktopEntries[entryIndex]
            var id = AppMatcher.normalizeId(entry && entry.id)
            if (id) index[id] = entry
        }
        desktopIndex = index
        scheduleRebuild()
    }

    function sequenceFor(key) {
        if (sequenceByKey[key] === undefined) {
            var next = {}
            for (var existing in sequenceByKey) next[existing] = sequenceByKey[existing]
            next[key] = nextSequence
            nextSequence += 1
            sequenceByKey = next
        }
        return sequenceByKey[key]
    }

    function labelFor(name, fallback) {
        var value = String(name || fallback || "APP").replace(/\s+/g, " ").trim().toUpperCase()
        return value.slice(0, 14)
    }

    function entryFor(desktopId) {
        return desktopIndex[AppMatcher.normalizeId(desktopId)] || null
    }

    function iconSourceFor(entry) {
        if (!entry || !entry.icon) return ""

        var appLibrary = root.shell && root.shell.appLibrary
        if (appLibrary && typeof appLibrary.iconSource === "function") {
            return appLibrary.iconSource(String(entry.icon))
        }
        return Quickshell.iconPath(String(entry.icon), true)
    }

    function appendWindow(groups, record, aliases) {
        var result = AppMatcher.match(
            record.appId,
            desktopEntries,
            aliases,
            function(name) {
                return typeof DesktopEntries.heuristicLookup === "function"
                    ? DesktopEntries.heuristicLookup(name)
                    : null
            }
        )
        var entry = result && result.entry
        var desktopId = entry ? String(entry.id) : ""
        var normalizedAppId = AppMatcher.normalizeId(record.appId)
        var key = desktopId ? "desktop:" + AppMatcher.normalizeId(desktopId) : "running:" + normalizedAppId

        if (!groups[key]) {
            groups[key] = {
                key: key,
                desktopId: desktopId,
                appId: String(record.appId || ""),
                entry: entry,
                windows: [],
                sequence: sequenceFor(key)
            }
        }
        groups[key].windows.push(record)
    }

    function makeItem(group, desktopId, pinned, slot) {
        var resolvedDesktopId = desktopId || (group && group.desktopId ? group.desktopId : "")
        var entry = resolvedDesktopId ? entryFor(resolvedDesktopId) : group.entry
        // ToplevelManager does not promise a stable order, so cycling would jump
        // around as windows are re-enumerated. Sorting by the Hyprland address
        // keeps "next window" meaning the same window twice in a row.
        var windows = group ? group.windows.slice() : []
        windows.sort(function(first, second) {
            return String(first.key || "") < String(second.key || "") ? -1
                : String(first.key || "") > String(second.key || "") ? 1 : 0
        })
        var active = false
        var urgent = false
        for (var index = 0; index < windows.length; index += 1) {
            active = active || !!windows[index].active
            urgent = urgent || !!windows[index].urgent
        }

        var name = entry ? String(entry.name || resolvedDesktopId) : (group ? group.appId : resolvedDesktopId)
        var icon = entry ? String(entry.icon || "") : ""
        return {
            key: pinned ? "desktop:" + AppMatcher.normalizeId(resolvedDesktopId) : group.key,
            desktopId: resolvedDesktopId,
            appId: group ? group.appId : resolvedDesktopId,
            name: name,
            shortLabel: labelFor(name, resolvedDesktopId),
            icon: icon,
            iconSource: icon ? iconSourceFor(entry) : "",
            pinned: pinned,
            missing: !entry,
            running: windows.length > 0,
            active: active,
            urgent: urgent,
            windowCount: windows.length,
            windows: windows,
            slot: slot
        }
    }

    function rebuild() {
        var configuration = currentConfig()
        var aliases = configuration.aliases || {}
        var groups = {}
        var records = root.windowService && root.windowService.records
            ? root.windowService.records
            : []

        for (var recordIndex = 0; recordIndex < records.length; recordIndex += 1) {
            if (records[recordIndex].appId) appendWindow(groups, records[recordIndex], aliases)
        }

        var nextItems = []
        var pinnedKeys = {}
        var pinned = Array.isArray(configuration.pinned) ? configuration.pinned : []
        for (var pinIndex = 0; pinIndex < pinned.length; pinIndex += 1) {
            var pin = pinned[pinIndex]
            if (!pin || !pin.desktopId) continue
            var desktopId = String(pin.desktopId).trim()
            var key = "desktop:" + AppMatcher.normalizeId(desktopId)
            var group = groups[key] || {
                key: key,
                desktopId: desktopId,
                appId: desktopId,
                entry: entryFor(desktopId),
                windows: [],
                sequence: sequenceFor(key)
            }
            pinnedKeys[key] = true
            nextItems.push(makeItem(group, desktopId, true, pinIndex + 1))
        }

        if (configuration.behavior && configuration.behavior.showRunningUnpinned) {
            var transientGroups = []
            for (var groupKey in groups) {
                if (!pinnedKeys[groupKey] && groups[groupKey].windows.length > 0) {
                    transientGroups.push(groups[groupKey])
                }
            }
            transientGroups.sort(function(first, second) { return first.sequence - second.sequence })
            for (var transientIndex = 0; transientIndex < transientGroups.length; transientIndex += 1) {
                nextItems.push(makeItem(transientGroups[transientIndex], "", false, 0))
            }
        }

        items = nextItems
    }

    function scheduleRebuild() {
        rebuildTimer.restart()
    }

    function launch(desktopId) {
        var entry = entryFor(desktopId)
        if (!entry) {
            var missingId = String(desktopId || "")
            console.warn("OmaDock: no desktop entry for " + (missingId || "the requested application"))
            launchFailed(missingId)
            return false
        }

        var appLibrary = root.shell && root.shell.appLibrary
        if (appLibrary && typeof appLibrary.launch === "function") {
            appLibrary.launch(String(entry.id || desktopId), String(entry.name || desktopId))
            return true
        }

        if (typeof entry.execute !== "function") {
            console.warn("OmaDock: desktop entry cannot be launched: " + String(entry.id || desktopId))
            launchFailed(String(desktopId || ""))
            return false
        }
        entry.execute()
        return true
    }

    function focusWindow(record) {
        if (!record || !record.toplevel || typeof record.toplevel.activate !== "function") return false
        record.toplevel.activate()
        return true
    }

    function focusOrLaunch(item) {
        if (!item) return false
        if (item.windowCount > 0) {
            if (item.windowCount === 1) return focusWindow(item.windows[0])
            return focusNext(item)
        }
        if (item.missing) {
            launch(item.desktopId)
            return false
        }
        return launch(item.desktopId)
    }

    function focusNext(item) {
        if (!item || item.windowCount === 0) return false
        var nextIndex = ActionModel.nextWindowIndex(item.windows)
        if (nextIndex < 0) return false
        return focusWindow(item.windows[nextIndex])
    }

    function focusPrevious(item) {
        if (!item || item.windowCount === 0) return false
        var previousIndex = ActionModel.previousWindowIndex(item.windows)
        if (previousIndex < 0) return false
        return focusWindow(item.windows[previousIndex])
    }

    function launchNew(item) {
        if (!item || item.missing) {
            if (item) launch(item.desktopId)
            return false
        }
        return launch(item.desktopId)
    }

    function closeActive(item) {
        if (!item || item.windowCount === 0) return false
        for (var index = 0; index < item.windows.length; index += 1) {
            var record = item.windows[index]
            if (record.active && record.toplevel && typeof record.toplevel.close === "function") {
                record.toplevel.close()
                return true
            }
        }
        return false
    }

    Timer {
        id: rebuildTimer
        interval: 0
        repeat: false
        onTriggered: root.rebuild()
    }

    Connections {
        target: DesktopEntries.applications
        function onObjectInsertedPost() { root.refreshDesktopEntries() }
        function onObjectRemovedPost() { root.refreshDesktopEntries() }
    }

    Connections {
        target: root.configService || null
        function onConfigurationChanged() { root.scheduleRebuild() }
    }

    Connections {
        target: root.windowService || null
        function onRecordsChanged() { root.scheduleRebuild() }
    }

    Component.onCompleted: {
        root.refreshDesktopEntries()
        root.scheduleRebuild()
    }
}
