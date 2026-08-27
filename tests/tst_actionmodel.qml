import QtTest
import "../models/ActionModel.js" as ActionModel

TestCase {
    name: "ActionModel"

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
