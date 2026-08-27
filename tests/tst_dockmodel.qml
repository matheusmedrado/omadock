import QtTest
import "../models/DockModel.js" as DockModel

TestCase {
    name: "DockModel"

    function test_defaultSurfaceMetrics() {
        var metrics = DockModel.surfaceMetrics({})
        compare(metrics.glyphSize, 16)
        compare(metrics.itemHeight, 28)
        compare(metrics.gap, 4)
        compare(metrics.edgeMargin, 8)
        compare(metrics.contentPadding, 5)
        compare(metrics.itemPadding, 6)
        compare(metrics.surfaceHeight, 46)
    }

    function test_metricsRespectBounds() {
        var metrics = DockModel.surfaceMetrics({ appearance: {
            iconSize: 100,
            itemSize: 1,
            gap: -4,
            edgeMargin: 100
        }})
        compare(metrics.glyphSize, 32)
        compare(metrics.itemHeight, 40)
        compare(metrics.gap, 0)
        compare(metrics.edgeMargin, 32)
        compare(metrics.surfaceHeight, 82)
    }

    function test_comfortableDensityAddsPadding() {
        var metrics = DockModel.surfaceMetrics({ appearance: { density: "comfortable" } })
        compare(metrics.contentPadding, 8)
        compare(metrics.itemPadding, 8)
        compare(metrics.surfaceHeight, 52)
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
