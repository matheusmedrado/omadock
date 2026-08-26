import QtQuick
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
