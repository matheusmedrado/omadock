import QtTest
import "../models/ActionModel.js" as ActionModel

TestCase {
    name: "ActionModel"

    function stubService() {
        return {
            calls: [],
            focusOrLaunch: function(item) { this.calls.push("focusOrLaunch"); return true },
            launchNew: function(item) { this.calls.push("launchNew"); return true },
            closeActive: function(item) { this.calls.push("closeActive"); return true },
            focusNext: function(item) { this.calls.push("focusNext"); return true },
            focusPrevious: function(item) { this.calls.push("focusPrevious"); return true }
        }
    }

    // An application that is uninstalled, or was never installed on this
    // machine, still has to be removable. Both routes out were gated on the
    // desktop entry resolving, which left the pin stuck in the dock forever.
    function test_aPinIsRemovableEvenWhenTheApplicationIsGone() {
        var gone = { pinned: true, missing: true, desktopId: "com.mitchellh.ghostty",
                     windowCount: 0 }
        var keys = ActionModel.actionsForItem(gone).map(function(a) { return a.key })
        compare(keys.indexOf("unpin") >= 0, true, "a missing pin must still offer unpin")
        compare(keys.indexOf("launch-new"), -1, "a missing application cannot be launched")
        compare(keys.indexOf("pin"), -1)
    }

    function test_pinningStillRequiresSomethingLaunchable() {
        var unmatched = { pinned: false, missing: true, desktopId: "", windowCount: 1 }
        var keys = ActionModel.actionsForItem(unmatched).map(function(a) { return a.key })
        compare(keys.indexOf("pin"), -1, "an unmatched window has no desktop entry to pin")
        compare(keys.indexOf("unpin"), -1)

        var running = { pinned: false, missing: false, desktopId: "zen", windowCount: 1 }
        var runningKeys = ActionModel.actionsForItem(running).map(function(a) { return a.key })
        compare(runningKeys.indexOf("pin") >= 0, true)
    }

    function test_aPinWithoutADesktopIdOffersNothingToRemove() {
        var broken = { pinned: true, missing: true, desktopId: "", windowCount: 0 }
        var keys = ActionModel.actionsForItem(broken).map(function(a) { return a.key })
        compare(keys.indexOf("unpin"), -1)
    }

    function test_pointerActionsFallBackWhenUnconfigured() {
        compare(ActionModel.clickAction({}), "focus-or-launch")
        compare(ActionModel.middleClickAction({}), "launch-new")
        compare(ActionModel.wheelAction({}), "cycle-windows")

        var bogus = { behavior: { clickAction: "explode", wheelAction: 7 } }
        compare(ActionModel.clickAction(bogus), "focus-or-launch")
        compare(ActionModel.wheelAction(bogus), "cycle-windows")
    }

    function test_configuredPointerActionsAreHonoured() {
        var configuration = { behavior: {
            clickAction: "launch-new",
            middleClickAction: "close-active",
            wheelAction: "none"
        }}
        compare(ActionModel.clickAction(configuration), "launch-new")
        compare(ActionModel.middleClickAction(configuration), "close-active")
        compare(ActionModel.wheelAction(configuration), "none")
    }

    function test_performActionDispatchesToTheService() {
        var service = stubService()
        var item = { windowCount: 2 }

        ActionModel.performAction("focus-or-launch", service, item, true)
        ActionModel.performAction("launch-new", service, item, true)
        ActionModel.performAction("close-active", service, item, true)
        ActionModel.performAction("cycle-windows", service, item, true)
        ActionModel.performAction("cycle-windows", service, item, false)
        compare(service.calls.join(","),
                "focusOrLaunch,launchNew,closeActive,focusNext,focusPrevious")
    }

    function test_performActionIgnoresNoneAndMissingTargets() {
        var service = stubService()
        compare(ActionModel.performAction("none", service, { windowCount: 1 }, true), false)
        compare(ActionModel.performAction("launch-new", null, { windowCount: 1 }, true), false)
        compare(ActionModel.performAction("launch-new", service, null, true), false)
        compare(service.calls.length, 0)
    }

    function test_focusOnlyDoesNotLaunchAnIdleApplication() {
        var service = stubService()
        compare(ActionModel.performAction("focus-only", service, { windowCount: 0 }, true), false)
        compare(service.calls.length, 0)
        compare(ActionModel.performAction("focus-only", service, { windowCount: 1 }, true), true)
        compare(service.calls.join(","), "focusOrLaunch")
    }

    function test_cyclingWrapsInBothDirections() {
        var windows = [{ active: false }, { active: true }, { active: false }]
        compare(ActionModel.nextWindowIndex(windows), 2)
        compare(ActionModel.previousWindowIndex(windows), 0)

        var last = [{ active: false }, { active: true }]
        compare(ActionModel.nextWindowIndex(last), 0)

        var first = [{ active: true }, { active: false }]
        compare(ActionModel.previousWindowIndex(first), 1)
    }

    function test_cyclingWithNoActiveWindowPicksAnEnd() {
        var windows = [{ active: false }, { active: false }]
        compare(ActionModel.nextWindowIndex(windows), 0)
        compare(ActionModel.previousWindowIndex(windows), 1)
        compare(ActionModel.nextWindowIndex([]), -1)
        compare(ActionModel.previousWindowIndex([]), -1)
    }

    function test_cyclesAfterActiveWindow() {
        var windows = [{ active: false }, { active: true }, { active: false }]
        compare(ActionModel.nextWindowIndex(windows), 2)
    }

    function test_cyclesFromLastToFirst() {
        compare(ActionModel.nextWindowIndex([{ active: false }, { active: true }]), 0)
    }

    function test_startsWithFirstWindowWhenNoneIsActive() {
        compare(ActionModel.nextWindowIndex([{ active: false }, { active: false }]), 0)
    }

    function test_unmatchedItemCannotLaunchOrPin() {
        var actions = ActionModel.actionsForItem({
            missing: true,
            pinned: true,
            desktopId: "",
            windowCount: 1
        })
        compare(actions.length, 1)
        compare(actions[0].key, "close-active")
    }

    function test_menuActionsForPinnedItem() {
        var actions = ActionModel.actionsForItem({
            missing: false,
            pinned: true,
            desktopId: "example.app",
            windowCount: 2
        })
        compare(actions.length, 4)
        compare(actions[0].key, "launch-new")
        compare(actions[1].key, "focus-next")
        compare(actions[2].key, "unpin")
        compare(actions[3].key, "close-active")
    }
}
