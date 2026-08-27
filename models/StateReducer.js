.pragma library

function initialState() {
    return {
        name: "HIDDEN",
        generation: 0
    }
}

// The dock sits one edge margin above the screen edge, so a pointer resting on
// the reveal sensor is never over the dock itself. Without treating the edge as
// a hold, a dock revealed from the edge hides again as soon as the hide delay
// expires and then re-reveals, flickering under a stationary pointer.
function heldOpen(input) {
    return !!(input.dockHovered || input.edgeHovered || input.dragActive
        || input.menuOpen || input.forcedReveal)
}

function nextState(current, name) {
    return {
        name: name,
        generation: (current && Number(current.generation) || 0) + 1
    }
}

function shouldReveal(input) {
    if (input.hideMode === "never") return true
    if (heldOpen(input)) return true
    return input.hideMode === "smart" && !input.windowConflict && !input.workspaceChanging
}

function reduce(current, input) {
    var state = current || initialState()
    var values = input || {}
    var hideMode = values.hideMode || "smart"

    if (!values.monitorEnabled || values.fullscreen) {
        return state.name === "SUSPENDED" ? state : nextState(state, "SUSPENDED")
    }

    if (state.name === "SUSPENDED") {
        return shouldReveal({
            hideMode: hideMode,
            windowConflict: !!values.windowConflict,
            workspaceChanging: !!values.workspaceChanging,
            dockHovered: !!values.dockHovered,
            dragActive: !!values.dragActive,
            menuOpen: !!values.menuOpen,
            forcedReveal: !!values.forcedReveal
        }) ? nextState(state, "REVEALING") : nextState(state, "HIDDEN")
    }

    switch (state.name) {
    case "HIDDEN":
        if (hideMode === "never" || values.forcedReveal || values.dockHovered
                || values.dragActive || values.menuOpen) {
            return nextState(state, "REVEALING")
        }
        if (values.edgeHovered) {
            return values.revealDelayElapsed ? nextState(state, "REVEALING") : nextState(state, "REVEAL_PENDING")
        }
        if (shouldReveal({
                hideMode: hideMode,
                windowConflict: !!values.windowConflict,
                workspaceChanging: !!values.workspaceChanging,
                dockHovered: false,
                dragActive: false,
                menuOpen: false,
                forcedReveal: false
            })) {
            return nextState(state, "REVEALING")
        }
        return state

    case "REVEAL_PENDING":
        if (values.forcedReveal || values.dockHovered || values.dragActive || values.menuOpen) {
            return nextState(state, "REVEALING")
        }
        if (!values.edgeHovered) return nextState(state, "HIDDEN")
        return values.revealDelayElapsed ? nextState(state, "REVEALING") : state

    case "REVEALING":
        return values.animationFinished ? nextState(state, "SHOWN") : state

    case "SHOWN":
        if (heldOpen(values) || hideMode === "never" || values.workspaceChanging) return state
        if (hideMode === "always" || (hideMode === "smart" && values.windowConflict)) {
            return values.hideDelayElapsed ? nextState(state, "HIDING") : nextState(state, "HIDE_PENDING")
        }
        return state

    case "HIDE_PENDING":
        if (heldOpen(values) || hideMode === "never"
                || (hideMode === "smart" && !values.windowConflict)
                || values.workspaceChanging) return nextState(state, "SHOWN")
        return values.hideDelayElapsed ? nextState(state, "HIDING") : state

    case "HIDING":
        if (heldOpen(values) || values.edgeHovered
                || (hideMode === "smart" && !values.windowConflict && !values.workspaceChanging)) {
            return nextState(state, "REVEALING")
        }
        return values.animationFinished ? nextState(state, "HIDDEN") : state
    }

    return nextState(state, "HIDDEN")
}
