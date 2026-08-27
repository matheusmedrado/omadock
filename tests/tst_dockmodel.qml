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
}
