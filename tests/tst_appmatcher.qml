import QtTest
import "../models/AppMatcher.js" as AppMatcher

TestCase {
    name: "AppMatcher"

    function test_normalizeDesktopSuffix() {
        compare(AppMatcher.normalizeId("Example.App.desktop"), "example.app")
    }
}
