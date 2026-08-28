import QtTest
import "../models/DockModel.js" as DockModel

TestCase {
    name: "DockModel"

    function test_defaultSurfaceMetrics() {
        var metrics = DockModel.surfaceMetrics({})
        compare(metrics.glyphSize, 28)
        compare(metrics.itemHeight, 40)
        compare(metrics.gap, 4)
        compare(metrics.edgeMargin, 8)
        compare(metrics.contentPadding, 7)
        compare(metrics.itemPadding, 8)
        compare(metrics.ditherCell, 2)
        compare(metrics.surfaceHeight, 62)
    }

    function test_metricsRespectBounds() {
        var metrics = DockModel.surfaceMetrics({ appearance: {
            iconSize: 100,
            itemSize: 1,
            gap: -4,
            edgeMargin: 100
        }})
        compare(metrics.glyphSize, 42)
        compare(metrics.itemHeight, 50)
        compare(metrics.gap, 0)
        compare(metrics.edgeMargin, 32)
        compare(metrics.surfaceHeight, 96)
    }

    function test_comfortableDensityAddsPadding() {
        var metrics = DockModel.surfaceMetrics({ appearance: { density: "comfortable" } })
        compare(metrics.contentPadding, 10)
        compare(metrics.itemPadding, 10)
        compare(metrics.surfaceHeight, 68)
    }

    function test_dragLeavesStripOnlyWhenPulledClearVertically() {
        var height = 54
        var threshold = 30

        // Inside the strip, and within the threshold either side of it.
        compare(DockModel.dragLeavesStrip(27, height, threshold), false)
        compare(DockModel.dragLeavesStrip(-29, height, threshold), false)
        compare(DockModel.dragLeavesStrip(height + 29, height, threshold), false)

        // Pulled clear.
        compare(DockModel.dragLeavesStrip(-31, height, threshold), true)
        compare(DockModel.dragLeavesStrip(height + 31, height, threshold), true)
    }

    function test_dragLeavesStripIgnoresNonsenseInput() {
        compare(DockModel.dragLeavesStrip(NaN, 54, 30), false)
        compare(DockModel.dragLeavesStrip(-100, NaN, 30), false)
        compare(DockModel.dragLeavesStrip(-100, 54, NaN), false)
        compare(DockModel.dragLeavesStrip(-100, 54, -1), false)
    }

    // A horizontal drag past either end is how an item is moved to the front or
    // back, so it must never be mistaken for dragging the item out.
    function test_horizontalDragNeverLeavesTheStrip() {
        for (var y = 0; y <= 54; y += 6) {
            compare(DockModel.dragLeavesStrip(y, 54, 30), false)
        }
    }

    function test_visualLabelsUseCompactTerminalForms() {
        compare(DockModel.slotLabel(3), "03")
        compare(DockModel.slotLabel(123), "23")
        compare(DockModel.slotLabel(0), "")
        compare(DockModel.instanceCountLabel(1), "")
        compare(DockModel.instanceCountLabel(2), "2x")
        compare(DockModel.instanceCountLabel(2.9), "2x")
        compare(DockModel.fallbackGlyph("Ghostty!", "fallback"), "GH")
        compare(DockModel.fallbackGlyph("", "??"), "?")
    }

    function makeWindow(overrides) {
        var window = {
            key: "0x1",
            active: true,
            monitorName: "DP-1",
            screenNames: ["DP-1"],
            toplevel: null,
            geometry: { x: 0, y: 0, width: 800, height: 600 }
        }
        for (var key in overrides) window[key] = overrides[key]
        return window
    }

    function makeItem(overrides) {
        var item = {
            key: "desktop:ghostty",
            desktopId: "ghostty",
            appId: "com.mitchellh.ghostty",
            name: "Ghostty",
            shortLabel: "GHOSTTY",
            icon: "ghostty",
            iconSource: "",
            categories: "System;TerminalEmulator;",
            pinned: true,
            missing: false,
            running: true,
            active: true,
            urgent: false,
            windowCount: 1,
            windows: [makeWindow({})],
            slot: 1
        }
        for (var key in overrides) item[key] = overrides[key]
        return item
    }

    function test_identicalItemsCompareEqual() {
        verify(DockModel.sameItems([makeItem({})], [makeItem({})]))
        verify(DockModel.sameItems([], []))
    }

    function test_itemFieldChangesAreChanges() {
        var fields = {
            key: "desktop:other",
            desktopId: "other",
            appId: "other",
            name: "Other",
            shortLabel: "OTHER",
            icon: "other",
            iconSource: "file:///other",
            categories: "Utility;",
            pinned: false,
            missing: true,
            running: false,
            active: false,
            urgent: true,
            windowCount: 2,
            slot: 2
        }
        for (var field in fields) {
            var overrides = {}
            overrides[field] = fields[field]
            verify(!DockModel.sameItems([makeItem({})], [makeItem(overrides)]),
                   "expected a change in " + field + " to be reported")
        }
    }

    // Moving or resizing a window changes its geometry on every frame, and none
    // of it changes what the strip draws. Letting it through would rebuild every
    // delegate for the length of the drag.
    function test_windowGeometryDoesNotChangeTheStrip() {
        verify(DockModel.sameItems(
            [makeItem({})],
            [makeItem({ windows: [makeWindow({
                geometry: { x: 40, y: 40, width: 1200, height: 900 }
            })] })]
        ))
    }

    function test_consumedWindowFieldsAreChanges() {
        var fields = {
            key: "0x2",
            active: false,
            monitorName: "HDMI-1",
            toplevel: { id: "replaced" }
        }
        for (var field in fields) {
            var overrides = {}
            overrides[field] = fields[field]
            verify(!DockModel.sameItems(
                [makeItem({})],
                [makeItem({ windows: [makeWindow(overrides)] })]
            ), "expected a change in window " + field + " to be reported")
        }
        verify(!DockModel.sameItems(
            [makeItem({})],
            [makeItem({ windows: [makeWindow({ screenNames: ["HDMI-1"] })] })]
        ))
    }

    // Cycling steps through the window list in order, so the same windows in a
    // different order is a different item.
    function test_windowOrderIsCompared() {
        var first = makeWindow({ key: "0x1" })
        var second = makeWindow({ key: "0x2", active: false })
        verify(!DockModel.sameItems(
            [makeItem({ windows: [first, second], windowCount: 2 })],
            [makeItem({ windows: [second, first], windowCount: 2 })]
        ))
    }

    function test_itemListLengthIsCompared() {
        verify(!DockModel.sameItems([makeItem({})], []))
        verify(!DockModel.sameItems(
            [makeItem({})],
            [makeItem({}), makeItem({ key: "desktop:other" })]
        ))
    }

    function test_labelRevealRidesTheAnimationDuration() {
        compare(DockModel.labelRevealMs({ behavior: { animationMs: 240 } }), 240)
        // Motion turned off silences the label as well.
        compare(DockModel.labelRevealMs({ behavior: { animationMs: 0 } }), 0)
        // Same bounds the configuration validator applies.
        compare(DockModel.labelRevealMs({ behavior: { animationMs: 5000 } }), 500)
        compare(DockModel.labelRevealMs({ behavior: { animationMs: -20 } }), 0)
        compare(DockModel.labelRevealMs({}), 160)
        compare(DockModel.labelRevealMs(undefined), 160)
    }
}
