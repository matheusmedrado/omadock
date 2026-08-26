import QtQuick

Item {
    id: root

    property var shell
    property var manifest
    property var pluginRegistry
    property string omarchyPath: ""
    property bool forcedReveal: false

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
