import QtQuick
import qs.Commons
import "../models/DockModel.js" as DockModel
import "../models/PixelGlyphs.js" as PixelGlyphs

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
    property real dragPointerY: 0
    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemHeight: metrics.itemHeight
    readonly property int gap: metrics.gap
    readonly property int padding: metrics.contentPadding
    readonly property int itemCount: DockModel.toArray(items).length
    readonly property int pinnedCount: configuration
        ? DockModel.toArray(configuration.pinned).length : 0
    readonly property bool showPrompt: configuration.appearance
        && configuration.appearance.showPrompt !== false
    readonly property bool showDither: configuration.appearance
        && configuration.appearance.showDither !== false
    readonly property int ditherCell: metrics.ditherCell
    readonly property int glyphSize: metrics.glyphSize
    // Items carry their own label, so the strip is measured from what the row
    // actually lays out rather than from a fixed per-item width.
    readonly property real rowWidth: dockRow.implicitWidth

    implicitWidth: rowWidth + padding * 2
    implicitHeight: itemHeight + padding * 2
    width: implicitWidth
    height: implicitHeight

    function dragKey(itemRecord) {
        return String(itemRecord && (itemRecord.key || itemRecord.desktopId) || "item")
    }

    // A pinned entry is always draggable, installed or not, because dragging it
    // out of the strip is one of the two ways to remove it. Requiring a resolved
    // desktop entry closed that route for exactly the pins that need it.
    function canDrag(itemRecord) {
        if (!itemRecord || !String(itemRecord.desktopId || "")) return false
        return !!itemRecord.pinned || !itemRecord.missing
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

    // A pinned item pulled clear of the strip is on its way out, so it stops
    // looking for an insertion point.
    readonly property int removeThreshold: Math.round(root.itemHeight * 0.75)
    readonly property bool dragWillRemove: root.dragActive && root.dragSourcePinned
        && !!root.configService
        && DockModel.dragLeavesStrip(root.dragPointerY, root.height, root.removeThreshold)

    function updateDrag(pointerX, pointerY) {
        if (!root.dragActive) return
        root.dragPointerX = pointerX
        if (pointerY !== undefined) root.dragPointerY = pointerY
        root.dragTargetIndex = root.dragWillRemove ? -1 : root.targetForX(pointerX)
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
        root.dragPointerY = 0
    }

    function finishDrag(pointerX, pointerY) {
        if (!root.dragActive) return false
        if (pointerX !== undefined) root.updateDrag(pointerX, pointerY)

        var sourcePinned = root.dragSourcePinned
        var sourceIndex = root.dragSourcePinnedIndex
        var targetIndex = root.dragTargetIndex
        var desktopId = root.dragSourceDesktopId
        var removing = root.dragWillRemove
        root.clearDrag()

        if (!desktopId || !root.configService) return false
        if (removing) return root.configService.unpin(desktopId)
        if (targetIndex < 0) return false
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

    // One surface for the whole strip. Individual items are unbordered so the
    // dock reads as a single prompt line rather than a shelf of tiles.
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 10) : 0
        color: {
            var opacity = root.configuration.appearance
                && root.configuration.appearance.backgroundOpacity !== undefined
                ? root.configuration.appearance.backgroundOpacity : 1.0
            return Qt.rgba(Color.bar.background.r, Color.bar.background.g,
                           Color.bar.background.b, opacity)
        }
        border.color: Style.normalBorderColor
        border.width: Math.max(1, Style.normalBorderWidth)

        // Clipped to the rounded surface so the texture stops at the border
        // instead of squaring off the corners.
        Item {
            anchors.fill: parent
            anchors.margins: surface.border.width
            clip: true
            visible: root.showDither

            DitherPattern {
                anchors.fill: parent
                cell: root.ditherCell
                tint: Color.bar.text
                topCoverage: 0.0
                bottomCoverage: 0.42
                // Bias the ramp hard so the strip stays clear behind the labels
                // and the texture only gathers along the bottom edge.
                gamma: 3.4
                opacity: 0.11
            }
        }
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

        // The prompt is on the matrix too, a step finer than the application
        // glyphs so it reads as punctuation opening the line rather than as a
        // fourth entry in the strip.
        Item {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showPrompt
            implicitWidth: prompt.implicitWidth + Style.space(6)
            implicitHeight: prompt.implicitHeight

            DotMatrix {
                id: prompt
                anchors.centerIn: parent
                cells: PixelGlyphs.cellsFor("prompt")
                columns: PixelGlyphs.SIZE
                rows: PixelGlyphs.SIZE
                pitch: Math.max(2, Math.floor(root.glyphSize / PixelGlyphs.SIZE) - 1)
                tint: Color.accent
            }
        }

        Repeater {
            id: dockRepeater
            model: root.items

            delegate: Component {
                Row {
                    id: slot
                    required property var modelData
                    required property int index
                    spacing: root.gap

                    // Pinned entries come first, so the first unpinned item is
                    // where the running-application group begins.
                    readonly property bool startsRunningGroup: !modelData.pinned
                        && index === root.pinnedCount && index > 0

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: slot.startsRunningGroup
                        text: "│"
                        color: Util.alpha(Color.bar.text, 0.3)
                        font.family: Style.font.family
                        font.pixelSize: Style.font.bodySmall
                    }

                    DockItem {
                        itemRecord: slot.modelData
                        itemIndex: slot.index
                        configuration: root.configuration
                        appService: root.appService
                        configService: root.configService
                        monitorName: root.monitorName
                        hideController: root.hideController
                        dockContent: root
                        dragSource: root.dragActive && root.dragSourceIndex === slot.index
                        dockWindow: root.dockWindow
                    }
                }
            }
        }
    }

    Rectangle {
        visible: root.dragActive && root.dragTargetIndex >= 0
        x: root.insertionMarkerX
        y: dockRow.y - Style.space(4)
        width: 3
        height: root.itemHeight + Style.space(4)
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
