import QtQuick
import qs.Commons
import "../models/DockModel.js" as DockModel

Item {
    id: root

    property var items: []
    property var configuration: ({})
    property var appService
    property var dockWindow
    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemSize: metrics.itemSize
    readonly property int gap: metrics.gap
    readonly property int padding: Style.space(4)
    readonly property int itemCount: Array.isArray(items) ? items.length : 0

    implicitWidth: DockModel.contentWidth(itemCount, itemSize, gap) + padding * 2
    implicitHeight: itemSize + padding * 2
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 10) : 0
        color: {
            var opacity = root.configuration.appearance
                && root.configuration.appearance.backgroundOpacity !== undefined
                ? root.configuration.appearance.backgroundOpacity : 0.94
            return Qt.rgba(Color.bar.background.r, Color.bar.background.g,
                           Color.bar.background.b, opacity)
        }
        border.color: Color.muted
        border.width: 1
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            model: root.items

            delegate: Component {
                DockItem {
                    required property var modelData
                    itemRecord: modelData
                    configuration: root.configuration
                    appService: root.appService
                    dockWindow: root.dockWindow
                }
            }
        }
    }
}
