import QtTest
import "../models/AppMatcher.js" as AppMatcher

TestCase {
    name: "AppMatcher"

    function test_normalizeDesktopSuffix() {
        compare(AppMatcher.normalizeId("Example.App.desktop"), "example.app")
    }

    function test_exactAndCaseInsensitiveMatch() {
        var entries = [
            { id: "com.example.Editor", name: "Editor" }
        ]
        compare(AppMatcher.match("com.example.Editor.desktop", entries, {}).method, "exact")
        compare(AppMatcher.match("COM.EXAMPLE.EDITOR", entries, {}).method, "case-insensitive")
    }

    function test_aliasTakesPrecedence() {
        var entries = [
            { id: "org.example.browser", name: "Browser" },
            { id: "com.example.browser", name: "Browser 2" }
        ]
        var result = AppMatcher.match("org.example.browser", entries, {
            "org.example.browser": "com.example.browser"
        })
        compare(result.method, "alias")
        compare(result.entry.id, "com.example.browser")
    }

    function test_startupClassAndAmbiguousBasename() {
        var entries = [
            { id: "com.example.editor", startupClass: "EditorWindow" },
            { id: "org.other.editor" }
        ]
        compare(AppMatcher.match("EditorWindow", entries, {}).method, "startup-wm-class")
        verify(AppMatcher.match("editor", entries, {}) === null)
    }
}
