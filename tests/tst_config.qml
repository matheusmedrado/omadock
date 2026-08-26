import QtTest
import "../models/ConfigModel.js" as ConfigModel

TestCase {
    name: "ConfigModel"

    function test_supportedVersion() {
        verify(ConfigModel.isSupportedVersion(1))
        verify(!ConfigModel.isSupportedVersion(2))
    }
}
