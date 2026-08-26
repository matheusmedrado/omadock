import QtQuick
import Quickshell
import "components"
import "services"

Item {
    id: root

    property var shell
    property var manifest
    property var pluginRegistry
    property string omarchyPath: ""
    property bool forcedReveal: false

    ConfigService {
        id: configServiceObject
    }

    WindowService {
        id: windowServiceObject
    }

    AppService {
        id: appService
        configService: configServiceObject
        windowService: windowServiceObject
    }

    Variants {
        model: Quickshell.screens

        delegate: Component {
            DockInstance {
                required property var modelData
                screen: modelData
                configService: root.configServiceObject
                appService: root.appService
            }
        }
    }

    function open(payload) {
        forcedReveal = true
    }

    function close() {
        forcedReveal = false
    }

    function toggle(payload) {
        forcedReveal = !forcedReveal
    }

    function status() {
        return "ready forcedReveal=" + forcedReveal
    }
}
