import QtTest
import "../models/WindowModel.js" as WindowModel

TestCase {
    name: "WindowModel"

    function makeRecord(overrides) {
        var record = {
            key: "0x1",
            appId: "com.mitchellh.ghostty",
            title: "shell",
            active: true,
            urgent: false,
            minimized: false,
            maximized: false,
            fullscreen: false,
            mapped: true,
            floating: false,
            geometry: { x: 0, y: 0, width: 800, height: 600 },
            workspaceId: 1,
            workspaceName: "1",
            monitorId: 0,
            monitorName: "DP-1",
            screens: [],
            screenNames: ["DP-1"],
            toplevel: null,
            hyprToplevel: null
        }
        for (var key in overrides) record[key] = overrides[key]
        return record
    }

    function test_identicalRecordsCompareEqual() {
        verify(WindowModel.sameRecords([makeRecord({})], [makeRecord({})]))
    }

    function test_emptyListsCompareEqual() {
        verify(WindowModel.sameRecords([], []))
    }

    // The whole point of the comparison: an agent CLI rewriting its terminal
    // title must not count as a change, or the dock rebuilds itself once a
    // second for as long as that terminal is open.
    function test_titleOnlyChangeIsNotAChange() {
        verify(WindowModel.sameRecords(
            [makeRecord({ title: "◑ building" })],
            [makeRecord({ title: "◐ building" })]
        ))
    }

    function test_stateChangesAreChanges() {
        var fields = {
            appId: "org.gnome.Nautilus",
            active: false,
            urgent: true,
            minimized: true,
            maximized: true,
            fullscreen: true,
            mapped: false,
            floating: true,
            workspaceId: 2,
            workspaceName: "2",
            monitorId: 1,
            monitorName: "HDMI-1"
        }
        for (var field in fields) {
            var overrides = {}
            overrides[field] = fields[field]
            verify(!WindowModel.sameRecords([makeRecord({})], [makeRecord(overrides)]),
                   "expected a change in " + field + " to be reported")
        }
    }

    function test_geometryChangeIsAChange() {
        verify(!WindowModel.sameRecords(
            [makeRecord({})],
            [makeRecord({ geometry: { x: 0, y: 0, width: 800, height: 601 } })]
        ))
    }

    function test_missingGeometryIsComparedAgainstPresentGeometry() {
        verify(!WindowModel.sameRecords([makeRecord({})], [makeRecord({ geometry: null })]))
        verify(WindowModel.sameRecords(
            [makeRecord({ geometry: null })],
            [makeRecord({ geometry: null })]
        ))
    }

    // A replaced handle has to reach the item even when every value around it
    // matches, or the dock keeps acting on a toplevel that is gone.
    function test_replacedHandleIsAChange() {
        verify(!WindowModel.sameRecords(
            [makeRecord({ toplevel: { id: "a" } })],
            [makeRecord({ toplevel: { id: "b" } })]
        ))
        verify(!WindowModel.sameRecords(
            [makeRecord({ hyprToplevel: { id: "a" } })],
            [makeRecord({ hyprToplevel: { id: "b" } })]
        ))
    }

    function test_screenNamesAreCompared() {
        verify(!WindowModel.sameRecords(
            [makeRecord({})],
            [makeRecord({ screenNames: ["DP-1", "HDMI-1"] })]
        ))
    }

    function test_lengthAndOrderAreCompared() {
        var first = makeRecord({ key: "0x1" })
        var second = makeRecord({ key: "0x2" })
        verify(!WindowModel.sameRecords([first], [first, second]))
        verify(!WindowModel.sameRecords([first, second], [second, first]))
    }

    function event(name, data) {
        return { name: name, data: data === undefined ? "" : data }
    }

    // The two events an agent CLI's spinner generates once a second. Neither
    // may cost a refresh, or the dock pays for an IPC round trip per spinner
    // frame per terminal.
    function test_titleEventsAreNotRefreshEvents() {
        verify(!WindowModel.isRefreshEvent(event("windowtitle", "0x1")))
        verify(!WindowModel.isRefreshEvent(event("windowtitlev2", "0x1,building")))
        verify(!WindowModel.isRefreshEvent(event("activewindow", "ghostty,building")))
        verify(!WindowModel.isRefreshEvent(event("activewindowv2", "0x1")))
    }

    function test_windowLifecycleEventsRefresh() {
        var names = ["openwindow", "closewindow", "movewindow", "movewindowv2",
                     "fullscreen", "workspace", "workspacev2", "moveworkspace",
                     "moveworkspacev2", "monitoradded", "monitorremoved",
                     "focusedmon", "focusedmonv2", "changefloating", "urgent"]
        for (var index = 0; index < names.length; index += 1) {
            verify(WindowModel.isRefreshEvent(event(names[index], "")),
                   "expected " + names[index] + " to refresh")
        }
    }

    function test_unknownEventsDoNotRefresh() {
        verify(!WindowModel.isRefreshEvent(event("activelayout", "kb,us")))
        verify(!WindowModel.isRefreshEvent(event("", "")))
        verify(!WindowModel.isRefreshEvent(null))
    }

    function test_workspaceEventsAreRecognised() {
        verify(WindowModel.isWorkspaceEvent(event("workspace", "1")))
        verify(WindowModel.isWorkspaceEvent(event("workspacev2", "1,1")))
        verify(WindowModel.isWorkspaceEvent(event("moveworkspacev2", "1,1,DP-1")))
        verify(WindowModel.isWorkspaceEvent(event("focusedmonv2", "DP-1,1")))
        verify(!WindowModel.isWorkspaceEvent(event("openwindow", "")))
    }

    // Only the v2 form names the focused window. The v1 form carries the class
    // and title, so it says nothing when two windows of one application are
    // open -- and it is re-emitted whenever that title changes.
    function test_onlyTheAddressFormIdentifiesFocus() {
        compare(WindowModel.activeWindowAddress(event("activewindowv2", "0x1")), "0x1")
        compare(WindowModel.activeWindowAddress(event("activewindowv2", "")), "")
        compare(WindowModel.activeWindowAddress(event("activewindow", "ghostty,building")), null)
        compare(WindowModel.activeWindowAddress(event("openwindow", "0x1")), null)
    }

    function test_activeWindowEventsAreRecognised() {
        verify(WindowModel.isActiveWindowEvent(event("activewindow", "ghostty,x")))
        verify(WindowModel.isActiveWindowEvent(event("activewindowv2", "0x1")))
        verify(!WindowModel.isActiveWindowEvent(event("windowtitle", "0x1")))
        verify(!WindowModel.isActiveWindowEvent(event("openwindow", "")))
    }

    function test_eventNameIsReadFromAnyOfTheKnownFields() {
        verify(WindowModel.isRefreshEvent({ name: "openwindow" }))
        verify(WindowModel.isRefreshEvent({ event: "openwindow" }))
        verify(WindowModel.isRefreshEvent({ type: "OPENWINDOW" }))
    }
}
