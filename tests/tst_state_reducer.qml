import QtTest
import "../models/StateReducer.js" as StateReducer

TestCase {
    name: "StateReducer"

    function test_initialState() {
        var state = StateReducer.initialState()
        compare(state.name, "HIDDEN")
        compare(state.generation, 0)
    }

    function input(overrides) {
        var result = {
            hideMode: "smart",
            windowConflict: false,
            fullscreen: false,
            edgeHovered: false,
            dockHovered: false,
            dragActive: false,
            menuOpen: false,
            forcedReveal: false,
            monitorEnabled: true,
            workspaceChanging: false,
            revealDelayElapsed: false,
            hideDelayElapsed: false,
            animationFinished: false,
            reducedMotion: false
        }
        for (var key in overrides) result[key] = overrides[key]
        return result
    }

    function transition(state, overrides) {
        return StateReducer.reduce(state, input(overrides))
    }

    function test_smartDockRevealsWhenClear() {
        compare(transition(StateReducer.initialState(), {}).name, "REVEALING")
    }

    function test_edgeRevealNeedsDwell() {
        var pending = transition(StateReducer.initialState(), {
            windowConflict: true,
            edgeHovered: true
        })
        compare(pending.name, "REVEAL_PENDING")
        compare(transition(pending, { edgeHovered: true, revealDelayElapsed: true }).name, "REVEALING")
        compare(transition(pending, { edgeHovered: false }).name, "HIDDEN")
    }

    function test_revealAndHideAnimationsComplete() {
        var state = transition(StateReducer.initialState(), {})
        compare(state.name, "REVEALING")
        state = transition(state, { animationFinished: true })
        compare(state.name, "SHOWN")
        state = transition(state, { windowConflict: true })
        compare(state.name, "HIDE_PENDING")
        state = transition(state, { windowConflict: true, hideDelayElapsed: true })
        compare(state.name, "HIDING")
        compare(transition(state, { windowConflict: true, animationFinished: true }).name, "HIDDEN")
    }

    function test_holdsCancelPendingHideAndReverseHiding() {
        var shown = { name: "SHOWN", generation: 4 }
        var pending = transition(shown, { windowConflict: true })
        compare(pending.name, "HIDE_PENDING")
        compare(transition(pending, { windowConflict: true, menuOpen: true }).name, "SHOWN")
        var hiding = transition(pending, { windowConflict: true, hideDelayElapsed: true })
        compare(hiding.name, "HIDING")
        compare(transition(hiding, { windowConflict: true, dockHovered: true }).name, "REVEALING")
    }

    function test_alwaysModeUsesEdgeAndHidesAfterDelay() {
        var state = transition(StateReducer.initialState(), { hideMode: "always" })
        compare(state.name, "HIDDEN")
        state = transition(state, { hideMode: "always", edgeHovered: true, revealDelayElapsed: true })
        compare(state.name, "REVEALING")
        state = transition(state, { hideMode: "always", animationFinished: true })
        compare(state.name, "SHOWN")
        state = transition(state, { hideMode: "always" })
        compare(state.name, "HIDE_PENDING")
        compare(transition(state, { hideMode: "always", hideDelayElapsed: true }).name, "HIDING")
    }

    function test_neverModeIsShownAndFullscreenSuspends() {
        var state = transition(StateReducer.initialState(), { hideMode: "never" })
        compare(state.name, "REVEALING")
        compare(transition(state, { hideMode: "never", fullscreen: true }).name, "SUSPENDED")
        compare(transition({ name: "SUSPENDED", generation: 8 }, {
            hideMode: "never"
        }).name, "REVEALING")
    }

    function test_monitorDisableSuspendsAndGenerationInvalidatesCallbacks() {
        var state = transition(StateReducer.initialState(), { monitorEnabled: false })
        compare(state.name, "SUSPENDED")
        compare(state.generation, 1)
        compare(transition(state, { monitorEnabled: true, animationFinished: true }).name, "REVEALING")
        verify(state.generation < transition(state, { monitorEnabled: true }).generation)
    }
}
