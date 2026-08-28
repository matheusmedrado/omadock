import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import "../models/WindowModel.js" as WindowModel

Item {
    id: root

    property var records: []
    property int refreshDelayMs: 35
    property int ipcSettleMs: 25
    property int settleRetries: 0
    readonly property int maxSettleRetries: 4
    // Focus is tracked by address rather than by the `activewindow` payload,
    // which carries the focused window's title and so is re-emitted on every
    // spinner frame of a terminal running an agent CLI. Comparing addresses
    // means only a real focus change costs a refresh.
    property string activeAddress: ""
    signal workspaceTransition()

    function modelValues(model) {
        return model && model.values ? model.values : []
    }

    function numberOrNull(value) {
        return typeof value === "number" && isFinite(value) ? value : null
    }

    // Hyprland's `at` and `size` arrive as QVariantList, which Array.isArray
    // rejects even though the values are indexable. Test for length instead so
    // real geometry is not discarded.
    function pairFromIpc(value) {
        if (!value || typeof value !== "object") return null
        if (Number(value.length) < 2) return null
        return value
    }

    function rectangleFromIpc(ipc) {
        if (!ipc) return null
        var at = pairFromIpc(ipc.at)
        var size = pairFromIpc(ipc.size)
        if (!at || !size) return null
        var x = numberOrNull(at[0])
        var y = numberOrNull(at[1])
        var width = numberOrNull(size[0])
        var height = numberOrNull(size[1])
        if (x === null || y === null || width === null || height === null) return null
        if (width < 0 || height < 0) return null
        return { x: x, y: y, width: width, height: height }
    }

    function matchesIpc(toplevel, hyprToplevel) {
        var ipc = hyprToplevel && hyprToplevel.lastIpcObject
        if (!ipc) return false

        var appId = String(toplevel && toplevel.appId || "").toLowerCase()
        var className = String(ipc.class || ipc.initialClass || "").toLowerCase()
        if (appId && className && appId !== className) return false

        var title = String(toplevel && toplevel.title || "")
        var ipcTitle = String(ipc.title || "")
        return !title || !ipcTitle || title === ipcTitle
    }

    function hasIpcPayload(hyprToplevel) {
        var ipc = hyprToplevel && hyprToplevel.lastIpcObject
        return !!ipc && ipc.address !== undefined
    }

    // The `HyprlandToplevel` attached handle names the right window but is not
    // the entry Hyprland.toplevels populates: its workspace, monitor, and
    // lastIpcObject stay null even after refreshToplevels(). Take the address
    // from it and resolve the populated entry, or every record loses the
    // workspace and geometry that Smart Hide compares against.
    function hyprByAddress(address, hyprToplevels, usedIndexes) {
        if (!address) return null
        for (var index = 0; index < hyprToplevels.length; index += 1) {
            if (usedIndexes.indexOf(index) >= 0) continue
            if (String(hyprToplevels[index].address || "") !== address) continue
            if (!root.hasIpcPayload(hyprToplevels[index])) continue
            usedIndexes.push(index)
            return hyprToplevels[index]
        }
        return null
    }

    function hyprFor(toplevel, hyprToplevels, usedIndexes) {
        var attached = toplevel && toplevel.HyprlandToplevel
        var attachedAddress = attached && attached.address ? String(attached.address) : ""
        var byAddress = hyprByAddress(attachedAddress, hyprToplevels, usedIndexes)
        if (byAddress) return byAddress

        for (var index = 0; index < hyprToplevels.length; index += 1) {
            if (usedIndexes.indexOf(index) >= 0) continue
            if (hyprToplevels[index].wayland === toplevel
                    && root.hasIpcPayload(hyprToplevels[index])) {
                usedIndexes.push(index)
                return hyprToplevels[index]
            }
        }

        for (var exactIndex = 0; exactIndex < hyprToplevels.length; exactIndex += 1) {
            if (usedIndexes.indexOf(exactIndex) >= 0) continue
            if (matchesIpc(toplevel, hyprToplevels[exactIndex])) {
                var ipc = hyprToplevels[exactIndex].lastIpcObject
                var title = String(toplevel && toplevel.title || "")
                var ipcTitle = String(ipc && ipc.title || "")
                if (title && ipcTitle && title !== ipcTitle) continue
                usedIndexes.push(exactIndex)
                return hyprToplevels[exactIndex]
            }
        }

        var appId = String(toplevel && toplevel.appId || "").toLowerCase()
        for (var appIndex = 0; appIndex < hyprToplevels.length; appIndex += 1) {
            if (usedIndexes.indexOf(appIndex) >= 0) continue
            var appIpc = hyprToplevels[appIndex].lastIpcObject
            var className = String(appIpc && (appIpc.class || appIpc.initialClass) || "")
                .toLowerCase()
            if (appId && className === appId) {
                usedIndexes.push(appIndex)
                return hyprToplevels[appIndex]
            }
        }
        return attached || null
    }

    function workspaceId(workspace) {
        return workspace && workspace.id !== undefined ? workspace.id : null
    }

    function monitorName(monitor) {
        return monitor && monitor.name ? String(monitor.name) : ""
    }

    function screenNames(screens) {
        var names = []
        var count = screens && typeof screens === "object" ? Number(screens.length) : 0
        if (!isFinite(count)) return names
        for (var index = 0; index < count; index += 1) {
            if (screens[index] && screens[index].name) names.push(String(screens[index].name))
        }
        return names
    }

    function normalizedRecord(toplevel, hyprToplevel, index) {
        var ipc = hyprToplevel ? hyprToplevel.lastIpcObject : null
        var screens = toplevel.screens
        var monitor = hyprToplevel ? hyprToplevel.monitor : null
        var workspace = hyprToplevel ? hyprToplevel.workspace : null
        var geometry = rectangleFromIpc(ipc)
        var appId = String(toplevel.appId || (ipc && (ipc.class || ipc.initialClass)) || "")
        var title = String(toplevel.title || (hyprToplevel && hyprToplevel.title) || (ipc && ipc.title) || "")
        var address = hyprToplevel && hyprToplevel.address ? String(hyprToplevel.address) : ""

        return {
            key: address || "wayland:" + appId + ":" + index,
            appId: appId,
            title: title,
            active: !!(toplevel.activated || (hyprToplevel && hyprToplevel.activated)),
            urgent: !!(hyprToplevel && hyprToplevel.urgent),
            minimized: !!toplevel.minimized,
            maximized: !!toplevel.maximized || !!(ipc && ipc.maximized),
            fullscreen: !!toplevel.fullscreen || !!(ipc && ipc.fullscreen),
            mapped: ipc && ipc.mapped !== undefined ? !!ipc.mapped : true,
            floating: ipc && ipc.floating !== undefined ? !!ipc.floating : false,
            geometry: geometry,
            workspaceId: workspaceId(workspace),
            workspaceName: workspace && workspace.name ? String(workspace.name) : "",
            monitorId: monitor && monitor.id !== undefined ? monitor.id : null,
            monitorName: monitorName(monitor),
            screens: screens,
            screenNames: screenNames(screens),
            toplevel: toplevel,
            hyprToplevel: hyprToplevel
        }
    }

    function rebuild() {
        var toplevels = modelValues(ToplevelManager.toplevels)
        var hyprToplevels = modelValues(Hyprland.toplevels)
        var nextRecords = []
        var usedHyprIndexes = []
        for (var index = 0; index < toplevels.length; index += 1) {
            nextRecords.push(normalizedRecord(
                toplevels[index],
                hyprFor(toplevels[index], hyprToplevels, usedHyprIndexes),
                index
            ))
        }

        // refreshToplevels() answers asynchronously, so the settle delay can
        // land before Hyprland has filled in geometry. A record without a
        // workspace would read as "no conflict" and wrongly reveal the dock,
        // so retry a bounded number of times until the payload arrives.
        //
        // The retry has to come before the assignment. Publishing first and
        // then retrying handed the dock exactly the half-built set this guard
        // exists to reject: Smart Hide read it as an empty band, revealed, and
        // hid again when the real payload landed a moment later. After the
        // retries are spent the set is published as it stands, so a window
        // Hyprland never describes cannot leave the dock stuck.
        if (root.missingIpcPayload(nextRecords) && root.settleRetries < root.maxSettleRetries) {
            root.settleRetries += 1
            refreshTimer.restart()
            return
        }
        root.settleRetries = 0

        // Rebuilding always produces a fresh array, so without this the records
        // are republished on every event even when nothing about them moved,
        // and every dock item is destroyed and recreated underneath the pointer.
        if (WindowModel.sameRecords(root.records, nextRecords)) return
        records = nextRecords
    }

    function missingIpcPayload(candidateRecords) {
        for (var index = 0; index < candidateRecords.length; index += 1) {
            if (candidateRecords[index].workspaceId === null) return true
        }
        return false
    }

    function scheduleRefresh() {
        root.settleRetries = 0
        refreshTimer.restart()
    }

    function refresh() {
        if (typeof Hyprland.refreshToplevels === "function") Hyprland.refreshToplevels()
        settleTimer.restart()
    }

    function handleEvent(event) {
        if (WindowModel.isActiveWindowEvent(event)) {
            var address = WindowModel.activeWindowAddress(event)
            // The v1 form is ignored outright; it cannot say which window was
            // focused when two windows of one application are open.
            if (address === null || address === root.activeAddress) return
            root.activeAddress = address
            root.scheduleRefresh()
            return
        }

        if (WindowModel.isWorkspaceEvent(event)) root.workspaceTransition()
        if (WindowModel.isRefreshEvent(event)) root.scheduleRefresh()
    }

    function runtimeStatus() {
        var hyprToplevels = modelValues(Hyprland.toplevels)
        var hypr = []
        for (var index = 0; index < hyprToplevels.length; index += 1) {
            var candidate = hyprToplevels[index]
            var ipc = candidate && candidate.lastIpcObject
            hypr.push({
                appId: candidate && candidate.wayland ? candidate.wayland.appId : "",
                title: candidate && candidate.wayland ? candidate.wayland.title : "",
                address: candidate ? candidate.address : "",
                ipc: ipc || null
            })
        }
        return {
            toplevelCount: modelValues(ToplevelManager.toplevels).length,
            hyprToplevelCount: hypr.length,
            hyprToplevels: hypr
        }
    }

    Timer {
        id: refreshTimer
        interval: root.refreshDelayMs
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        id: settleTimer
        interval: root.ipcSettleMs
        repeat: false
        onTriggered: root.rebuild()
    }

    Connections {
        target: ToplevelManager
        function onActiveToplevelChanged() { root.scheduleRefresh() }
    }

    Connections {
        target: ToplevelManager.toplevels
        function onObjectInsertedPost() { root.scheduleRefresh() }
        function onObjectRemovedPost() { root.scheduleRefresh() }
    }

    Connections {
        target: Hyprland
        function onActiveToplevelChanged() { root.scheduleRefresh() }
        function onRawEvent(event) { root.handleEvent(event) }
    }

    Component.onCompleted: root.scheduleRefresh()
}
