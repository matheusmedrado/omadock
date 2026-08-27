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

    // Under reservation the answer must not depend on whether the dock is
    // currently reserving. A tiled window shrunk clear of the dock still counts,
    // because releasing the zone is exactly what would put it back.
    function test_reserveModeCountsAnyTiledWindowWhereverItSits() {
        var workspace = { id: 1 }
        var dockRect = { x: 0, y: 1140, width: 1920, height: 60 }
        var shrunk = {
            appId: "term", workspaceId: 1, monitorName: "eDP-1", mapped: true,
            floating: false, geometry: { x: 0, y: 0, width: 1920, height: 1080 }
        }

        compare(Geometry.conflicts(shrunk, dockRect, workspace, "eDP-1", false), false)
        compare(Geometry.conflicts(shrunk, dockRect, workspace, "eDP-1", true), true)
    }

    function test_reserveModeExemptsFloatingWindows() {
        var workspace = { id: 1 }
        var dockRect = { x: 0, y: 1140, width: 1920, height: 60 }
        var floating = {
            appId: "calc", workspaceId: 1, monitorName: "eDP-1", mapped: true,
            floating: true, geometry: { x: 40, y: 40, width: 400, height: 300 }
        }

        // An exclusive zone resizes the tiling area, so it never moves a
        // floating window and one cannot be displaced by the dock.
        compare(Geometry.conflicts(floating, dockRect, workspace, "eDP-1", true), false)
    }

    function test_reserveModeStillHonoursWorkspaceAndMonitor() {
        var workspace = { id: 1 }
        var dockRect = { x: 0, y: 1140, width: 1920, height: 60 }
        var elsewhere = {
            appId: "term", workspaceId: 2, monitorName: "eDP-1", mapped: true,
            floating: false, geometry: { x: 0, y: 0, width: 1920, height: 1080 }
        }
        var otherMonitor = {
            appId: "term", workspaceId: 1, monitorName: "HDMI-1", mapped: true,
            floating: false, geometry: { x: 0, y: 0, width: 1920, height: 1080 }
        }

        compare(Geometry.conflicts(elsewhere, dockRect, workspace, "eDP-1", true), false)
        compare(Geometry.conflicts(otherMonitor, dockRect, workspace, "eDP-1", true), false)
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
