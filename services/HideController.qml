import QtQuick
import Quickshell.Hyprland
import "../models/Geometry.js" as Geometry
import "../models/StateReducer.js" as StateReducer

Item {
    id: root

    property var configuration: ({})
    property var monitor
    property var windowService
    property var dockSurface
    property bool monitorEnabled: true
    property bool forcedReveal: false
    property bool dockHovered: false
    property bool edgeHovered: false
    property bool workspaceChanging: false
    property var holds: ({})
    property var visibilityState: StateReducer.initialState()
    property real revealProgress: 0
    property int modelRevision: 0
    property int animationGeneration: -1
    property int revealTimerGeneration: -1
    property int hideTimerGeneration: -1

    readonly property var behavior: configuration && configuration.behavior
        ? configuration.behavior : ({})
    readonly property string hideMode: behavior.hideMode || "smart"
    readonly property int revealDelayMs: typeof behavior.revealDelayMs === "number"
        ? behavior.revealDelayMs : 35
    readonly property int hideDelayMs: typeof behavior.hideDelayMs === "number"
        ? behavior.hideDelayMs : 320
    readonly property int animationMs: typeof behavior.animationMs === "number"
        ? behavior.animationMs : 160
    readonly property int workspaceSettleMs: typeof behavior.workspaceSettleMs === "number"
        ? behavior.workspaceSettleMs : 120
    readonly property string stateName: visibilityState.name
    readonly property string monitorName: monitor ? String(monitor.name || "") : ""
    readonly property bool menuOpen: hasHoldPrefix("menu:")
    readonly property bool dragActive: hasHoldPrefix("drag:")
    readonly property bool heldOpen: root.dockHovered || root.dragActive
        || root.menuOpen || root.forcedReveal
    readonly property bool fullscreen: {
        var revision = root.modelRevision
        return Geometry.workspaceHasFullscreen(
            root.monitor ? root.monitor.activeWorkspace : null,
            root.windowRecords(),
            root.monitorName
        )
    }
    readonly property bool windowConflict: {
        var revision = root.modelRevision
        return root.currentWindowConflict()
    }
    readonly property bool edgeEnabled: root.monitorEnabled
        && root.hideMode !== "never" && !root.fullscreen

    readonly property bool reserveSpace: !!behavior.reserveSpace
    // Space is held from the moment the reveal starts until the hide animation
    // has finished. Releasing it any earlier would let the windows grow back
    // under a dock that is still on screen, and -- because the conflict test
    // compensates for the zone -- would briefly read as "clear" and bounce the
    // dock back open.
    readonly property bool reservesSpace: root.reserveSpace && root.monitorEnabled
        && root.stateName !== "HIDDEN" && root.stateName !== "SUSPENDED"

    function windowRecords() {
        return root.windowService && Array.isArray(root.windowService.records)
            ? root.windowService.records : []
    }

    function currentWindowConflict() {
        if (root.hideMode !== "smart" || !root.monitor || !root.dockSurface) return false

        var dockRect = Geometry.dockRect(
            root.monitor,
            Number(root.dockSurface.dockWidth),
            Number(root.dockSurface.dockHeight),
            Number(root.dockSurface.edgeMargin)
        )
        var workspace = root.monitor.activeWorkspace
        if (!dockRect || !workspace) return false

        var records = root.windowRecords()
        for (var index = 0; index < records.length; index += 1) {
            if (Geometry.conflicts(records[index], dockRect, workspace,
                    root.monitorName, root.reserveSpace)) return true
        }
        return false
    }

    function hasHoldPrefix(prefix) {
        for (var key in root.holds) {
            if (root.holds[key] && key.indexOf(prefix) === 0) return true
        }
        return false
    }

    function setHold(source, key, active) {
        var holdKey = String(source || "hold") + ":" + String(key || "default")
        var next = {}
        for (var existing in root.holds) {
            if (root.holds[existing]) next[existing] = true
        }
        if (active) next[holdKey] = true
        else delete next[holdKey]
        root.holds = next
        root.scheduleEvaluate()
    }

    function input(overrides) {
        var values = {
            hideMode: root.hideMode,
            windowConflict: root.windowConflict,
            fullscreen: root.fullscreen,
            edgeHovered: root.edgeHovered,
            dockHovered: root.dockHovered,
            dragActive: root.dragActive,
            menuOpen: root.menuOpen,
            forcedReveal: root.forcedReveal,
            monitorEnabled: root.monitorEnabled,
            workspaceChanging: root.workspaceChanging,
            revealDelayElapsed: false,
            hideDelayElapsed: false,
            animationFinished: false,
            reducedMotion: root.animationMs === 0
        }
        for (var key in overrides) values[key] = overrides[key]
        return values
    }

    function dispatch(overrides) {
        var next = StateReducer.reduce(root.visibilityState, root.input(overrides || {}))
        if (next.name === root.visibilityState.name
                && next.generation === root.visibilityState.generation) return
        root.visibilityState = next
        root.applyState(next)

        // Entering a state can already satisfy the condition for leaving it —
        // a window that starts overlapping while the dock is still revealing
        // leaves SHOWN owing a hide that no further input change would trigger.
        // Re-evaluating settles that; dispatch is a no-op once the machine is
        // stable, so this terminates.
        root.scheduleEvaluate()
    }

    function applyState(next) {
        revealDelayTimer.stop()
        hideDelayTimer.stop()

        if (next.name === "SUSPENDED" || next.name === "HIDDEN") {
            revealAnimation.stop()
            root.animationGeneration = -1
            root.revealProgress = 0
            return
        }
        if (next.name === "SHOWN") {
            revealAnimation.stop()
            root.animationGeneration = -1
            root.revealProgress = 1
            return
        }
        if (next.name === "REVEAL_PENDING") {
            root.revealTimerGeneration = next.generation
            revealDelayTimer.start()
        } else if (next.name === "HIDE_PENDING") {
            root.hideTimerGeneration = next.generation
            hideDelayTimer.start()
        } else if (next.name === "REVEALING") {
            root.startAnimation(1, next.generation)
        } else if (next.name === "HIDING") {
            root.startAnimation(0, next.generation)
        }
    }

    function startAnimation(target, generation) {
        revealAnimation.stop()
        root.animationGeneration = generation
        revealAnimation.from = root.revealProgress
        revealAnimation.to = target
        revealAnimation.duration = root.animationMs
        if (root.animationMs === 0) {
            root.revealProgress = target
            if (root.visibilityState.generation === generation) root.dispatch({ animationFinished: true })
            return
        }
        revealAnimation.start()
    }

    function scheduleEvaluate() {
        evaluateTimer.restart()
    }

    function refreshModels() {
        root.modelRevision += 1
        root.scheduleEvaluate()
    }

    Timer {
        id: evaluateTimer
        interval: 0
        repeat: false
        onTriggered: root.dispatch({})
    }

    Timer {
        id: revealDelayTimer
        interval: root.revealDelayMs
        repeat: false
        onTriggered: {
            if (root.visibilityState.generation === root.revealTimerGeneration)
                root.dispatch({ revealDelayElapsed: true })
        }
    }

    Timer {
        id: hideDelayTimer
        interval: root.hideDelayMs
        repeat: false
        onTriggered: {
            if (root.visibilityState.generation === root.hideTimerGeneration)
                root.dispatch({ hideDelayElapsed: true })
        }
    }

    Timer {
        id: workspaceSettleTimer
        interval: root.workspaceSettleMs
        repeat: false
        onTriggered: {
            root.workspaceChanging = false
            root.refreshModels()
        }
    }

    NumberAnimation {
        id: revealAnimation
        target: root
        property: "revealProgress"
        easing.type: to === 1 ? Easing.OutCubic : Easing.InCubic
        onFinished: {
            if (root.visibilityState.generation === root.animationGeneration)
                root.dispatch({ animationFinished: true })
        }
    }

    Connections {
        target: root.windowService || null
        function onRecordsChanged() { root.refreshModels() }
        function onWorkspaceTransition() {
            root.workspaceChanging = true
            workspaceSettleTimer.restart()
            root.refreshModels()
        }
    }

    Connections {
        target: root.monitor || null
        function onActiveWorkspaceChanged() { root.refreshModels() }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.refreshModels() }
    }

    onConfigurationChanged: root.refreshModels()
    onMonitorEnabledChanged: root.scheduleEvaluate()
    onForcedRevealChanged: root.scheduleEvaluate()
    onDockHoveredChanged: root.scheduleEvaluate()
    onEdgeHoveredChanged: root.scheduleEvaluate()
    onWorkspaceChangingChanged: root.scheduleEvaluate()
    onMenuOpenChanged: root.scheduleEvaluate()
    onDragActiveChanged: root.scheduleEvaluate()
    onFullscreenChanged: root.scheduleEvaluate()
    onWindowConflictChanged: root.scheduleEvaluate()
    onHideModeChanged: root.scheduleEvaluate()

    Component.onCompleted: root.scheduleEvaluate()
}
