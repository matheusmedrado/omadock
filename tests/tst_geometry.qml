import QtTest
import "../models/Geometry.js" as Geometry

TestCase {
    name: "Geometry"

    function test_intersection() {
        verify(Geometry.intersects({ x: 0, y: 0, width: 10, height: 10 },
                                   { x: 5, y: 5, width: 10, height: 10 }))
        verify(!Geometry.intersects({ x: 0, y: 0, width: 10, height: 10 },
                                    { x: 10, y: 0, width: 10, height: 10 }))
    }

    function test_bottomDockRectSupportsNegativeMonitorOrigins() {
        var rectangle = Geometry.dockRect({ x: -1920, y: 0, width: 1920, height: 1080 },
                                           300, 60, 8)
        compare(rectangle.x, -1110)
        compare(rectangle.y, 1012)
        compare(rectangle.height, 68)
    }

    function test_fractionalMonitorGeometryStaysInCompositorCoordinates() {
        var rectangle = Geometry.dockRect({ x: -1280.5, y: 0.25, width: 1280.5, height: 720.5 },
                                           301.5, 60.5, 7.5)
        compare(rectangle.x, -791)
        compare(rectangle.y, 652.75)
        compare(rectangle.width, 301.5)
        compare(rectangle.height, 68)
    }

    function test_invalidDockDimensionsAreIgnored() {
        verify(Geometry.dockRect({ x: 0, y: 0, width: 1920, height: 1080 }, -1, 60, 8) === null)
        verify(Geometry.dockRect({ x: 0, y: 0, width: 0, height: 1080 }, 300, 60, 8) === null)
    }

    function test_conflictFallbacks() {
        var workspace = { id: 2, name: "2" }
        var protectedRect = { x: 0, y: 900, width: 400, height: 100 }
        verify(Geometry.conflicts({
            workspaceId: 2, monitorName: "DP-1", mapped: true, minimized: false,
            floating: false, geometry: null
        }, protectedRect, workspace, "DP-1"))
        verify(!Geometry.conflicts({
            workspaceId: 2, monitorName: "DP-1", mapped: true, minimized: false,
            floating: true, geometry: null
        }, protectedRect, workspace, "DP-1"))
        verify(!Geometry.conflicts({
            workspaceId: 1, monitorName: "DP-1", mapped: true, minimized: false,
            floating: false, geometry: { x: 0, y: 900, width: 400, height: 100 }
        }, protectedRect, workspace, "DP-1"))
        verify(Geometry.conflicts({
            workspaceId: "special", workspaceName: "special", monitorName: "DP-1",
            mapped: true, minimized: false, floating: false,
            geometry: { x: 0, y: 900, width: 400, height: 100 }
        }, protectedRect, { id: "special", name: "special" }, "DP-1"))
    }

    function test_fullscreenWorkspaceWins() {
        verify(Geometry.workspaceHasFullscreen({ id: 1, hasFullscreen: true }, [], "DP-1"))
        verify(Geometry.workspaceHasFullscreen({ id: 1, name: "1" }, [{
            workspaceId: 1, workspaceName: "1", monitorName: "DP-1", fullscreen: true
        }], "DP-1"))
    }
}
