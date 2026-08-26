import QtTest
import "../models/DockModel.js" as DockModel

TestCase {
    name: "DockModel"

    function test_defaultSurfaceMetrics() {
        var metrics = DockModel.surfaceMetrics({})
        compare(metrics.iconSize, 24)
        compare(metrics.itemSize, 44)
        compare(metrics.gap, 4)
        compare(metrics.edgeMargin, 8)
        compare(metrics.surfaceHeight, 60)
    }

    function test_metricsRespectBounds() {
        var metrics = DockModel.surfaceMetrics({ appearance: {
            iconSize: 100,
            itemSize: 1,
            gap: -4,
            edgeMargin: 100
        }})
        compare(metrics.iconSize, 48)
        compare(metrics.itemSize, 60)
        compare(metrics.gap, 0)
        compare(metrics.edgeMargin, 32)
        compare(metrics.surfaceHeight, 100)
    }

    function test_contentWidth() {
        compare(DockModel.contentWidth(0, 44, 4), 0)
        compare(DockModel.contentWidth(3, 44, 4), 140)
        compare(DockModel.contentWidth(2, 48, 0), 96)
    }
}
