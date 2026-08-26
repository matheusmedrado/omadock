import QtQuick
import qs.Commons
import "../models/DockModel.js" as DockModel

Item {
    id: root

    property var items: []
    property var configuration: ({})
    property var appService
    property var configService
    property string monitorName: ""
    property var hideController
    property var dockWindow
    property bool dragActive: false
    property int dragSourceIndex: -1
    property string dragSourceKey: ""
    property string dragSourceDesktopId: ""
    property bool dragSourcePinned: false
    property int dragSourcePinnedIndex: -1
    property int dragTargetIndex: -1
    property real dragPointerX: -1
    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemSize: metrics.itemSize
    readonly property int gap: metrics.gap
    readonly property int padding: Style.space(4)
    readonly property int itemCount: Array.isArray(items) ? items.length : 0
    readonly property int pinnedCount: configuration && Array.isArray(configuration.pinned)
        ? configuration.pinned.length : 0

    implicitWidth: DockModel.contentWidth(itemCount, itemSize, gap) + padding * 2
    implicitHeight: itemSize + padding * 2
    width: implicitWidth
    height: implicitHeight

    function dragKey(itemRecord) {
        return String(itemRecord && (itemRecord.key || itemRecord.desktopId) || "item")
    }

    function canDrag(itemRecord) {
        return !!itemRecord && !itemRecord.missing && !!String(itemRecord.desktopId || "")
    }

    function beginDrag(index, itemRecord) {
        if (root.dragActive || !root.configService || !root.canDrag(itemRecord)) return false

        root.dragActive = true
        root.dragSourceIndex = index
        root.dragSourceKey = root.dragKey(itemRecord)
        root.dragSourceDesktopId = String(itemRecord.desktopId || "")
        root.dragSourcePinned = !!itemRecord.pinned
        var slot = Number(itemRecord.slot)
        root.dragSourcePinnedIndex = root.dragSourcePinned
            ? (isFinite(slot) && slot > 0 ? Math.floor(slot) - 1 : index) : -1
        root.dragTargetIndex = -1
        root.dragPointerX = -1
        if (root.hideController) root.hideController.setHold("drag", root.dragSourceKey, true)
        return true
    }

    function pinnedEndX() {
        if (root.pinnedCount === 0) return dockRow.x + root.padding
        var last = null
        for (var index = 0; index < root.pinnedCount; index += 1) {
            if (root.dragSourcePinned && index === root.dragSourcePinnedIndex) continue
            last = dockRepeater.itemAt(index)
        }
        if (!last) return dockRow.x + root.padding
        return dockRow.x + last.x + last.width + root.gap / 2
    }

    function pinnedItemAtDestination(destination) {
        var visibleIndex = 0
        for (var index = 0; index < root.pinnedCount; index += 1) {
            if (root.dragSourcePinned && index === root.dragSourcePinnedIndex) continue
            if (visibleIndex === destination) return dockRepeater.itemAt(index)
            visibleIndex += 1
        }
        return null
    }

    function targetForX(pointerX) {
        if (!root.dragActive) return -1
        if (!root.dragSourcePinned && root.pinnedCount > 0 && pointerX > root.pinnedEndX()) return -1

        if (root.dragSourcePinned) {
            var source = dockRepeater.itemAt(root.dragSourcePinnedIndex)
            if (source && pointerX >= dockRow.x + source.x
                    && pointerX <= dockRow.x + source.x + source.width) {
                return root.dragSourcePinnedIndex
            }
        }

        var target = 0
        for (var index = 0; index < root.pinnedCount; index += 1) {
            if (root.dragSourcePinned && index === root.dragSourcePinnedIndex) continue
            var item = dockRepeater.itemAt(index)
            if (!item) continue
            var center = dockRow.x + item.x + item.width / 2
            if (pointerX < center) return target
            target += 1
        }
        return target
    }

    function updateDrag(pointerX) {
        if (!root.dragActive) return
        root.dragPointerX = pointerX
        root.dragTargetIndex = root.targetForX(pointerX)
    }

    function clearDrag() {
        if (root.hideController && root.dragSourceKey) {
            root.hideController.setHold("drag", root.dragSourceKey, false)
        }
        root.dragActive = false
        root.dragSourceIndex = -1
        root.dragSourceKey = ""
        root.dragSourceDesktopId = ""
        root.dragSourcePinned = false
        root.dragSourcePinnedIndex = -1
        root.dragTargetIndex = -1
        root.dragPointerX = -1
    }

    function finishDrag(pointerX) {
        if (!root.dragActive) return false
        if (pointerX !== undefined) root.updateDrag(pointerX)

        var sourcePinned = root.dragSourcePinned
        var sourceIndex = root.dragSourcePinnedIndex
        var targetIndex = root.dragTargetIndex
        var desktopId = root.dragSourceDesktopId
        root.clearDrag()

        if (targetIndex < 0 || !desktopId || !root.configService) return false
        if (sourcePinned) return root.configService.reorderPinned(sourceIndex, targetIndex)
        return root.configService.pinAt(desktopId, targetIndex)
    }

    function cancelDrag() {
        if (root.dragActive) root.clearDrag()
    }

    function cancelDragIf(itemRecord) {
        if (root.dragActive && root.dragSourceKey === root.dragKey(itemRecord)) root.cancelDrag()
    }

    readonly property real insertionMarkerX: {
        if (root.dragTargetIndex < 0) return -100
        var target = root.pinnedItemAtDestination(root.dragTargetIndex)
        if (target) return dockRow.x + target.x - root.gap / 2 - 1.5
        return root.pinnedEndX() - root.gap / 2 - 1.5
    }

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

    HoverHandler {
        id: dockHover
        onHoveredChanged: {
            if (root.hideController) root.hideController.dockHovered = hovered
        }
    }

    Component.onDestruction: {
        if (root.hideController) root.hideController.dockHovered = false
        root.cancelDrag()
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: root.gap

        Repeater {
            id: dockRepeater
            model: root.items

            delegate: Component {
                DockItem {
                    required property var modelData
                    required property int index
                    itemRecord: modelData
                    itemIndex: index
                    configuration: root.configuration
                    appService: root.appService
                    configService: root.configService
                    monitorName: root.monitorName
                    hideController: root.hideController
                    dockContent: root
                    dragSource: root.dragActive && root.dragSourceIndex === index
                    dockWindow: root.dockWindow
                }
            }
        }
    }

    Rectangle {
        visible: root.dragActive && root.dragTargetIndex >= 0
        x: root.insertionMarkerX
        y: dockRow.y - Style.space(4)
        width: 3
        height: root.itemSize + Style.space(8)
        radius: width / 2
        color: Color.accent
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.dragActive
        onActivated: root.cancelDrag()
    }

    Connections {
        target: root.configService || null
        function onConfigurationChanged() { root.cancelDrag() }
    }

}
