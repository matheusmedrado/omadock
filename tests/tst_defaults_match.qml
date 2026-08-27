import QtTest
import "../models/ConfigModel.js" as ConfigModel

// config/defaults.json documents the shipped configuration but is never read at
// runtime: ConfigModel.defaultConfig() is what a fresh install actually gets.
// The two silently drifted apart once already, so pin them together here.
TestCase {
    name: "DefaultsMatch"

    function test_documentedDefaultsMatchTheRuntimeDefaults() {
        var request = new XMLHttpRequest()
        request.open("GET", Qt.resolvedUrl("../config/defaults.json"), false)
        request.send(null)
        verify(request.responseText.length > 0, "config/defaults.json could not be read")

        var documented = JSON.parse(request.responseText)
        compare(JSON.stringify(documented), JSON.stringify(ConfigModel.defaultConfig()))
    }
}
