import QtQuick
import qs.Commons
import "../models/ActionModel.js" as ActionModel
import "../models/DockModel.js" as DockModel
import "../models/GlyphModel.js" as GlyphModel
import "../models/PixelGlyphs.js" as PixelGlyphs

Item {
    id: root

    property var itemRecord: ({})
    property var configuration: ({})
    property var appService
    property var configService
    property string monitorName: ""
    property var hideController
    property var dockContent
    property var dockWindow
    property int itemIndex: -1
    property bool hovered: false
    property bool pressed: false
    property bool contextMenuOpen: false
    property bool dragSource: false
    property bool dragStarted: false
    property bool suppressClick: false
    property real pressX: 0
    property real pressY: 0
    property int pressButton: Qt.NoButton
    property real wheelAccumulator: 0
    readonly property int dragThreshold: 8
    readonly property int wheelNotch: 120

    opacity: root.dragSource ? 0.4 : 1

    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemHeight: metrics.itemHeight
    readonly property int glyphSize: metrics.glyphSize
    readonly property int itemPadding: metrics.itemPadding
    // The marker sits on the glyph pitch so its dots line up with the matrix
    // above them.
    readonly property int markerPitch: Math.max(2, Math.floor(metrics.glyphSize / 7))
    readonly property int markerDots: 3
    readonly property bool localActive: hasLocalActiveWindow()
    readonly property bool running: !!root.itemRecord.running
    readonly property bool urgent: !!root.itemRecord.urgent
    readonly property bool hasContextActions: ActionModel.actionsForItem(root.itemRecord).length > 0
    readonly property string slotLabel: DockModel.slotLabel(root.itemRecord.slot)
    readonly property string countLabel: DockModel.instanceCountLabel(root.itemRecord.windowCount)
    readonly property string commandLabel: GlyphModel.commandLabel(
        root.itemRecord.name, root.itemRecord.desktopId, root.itemRecord.appId)
    readonly property bool showSlotNumbers: configuration.appearance
        && configuration.appearance.showSlotNumbers !== false
    readonly property string showLabels: configuration.appearance && configuration.appearance.showLabels
        ? configuration.appearance.showLabels : "always"
    readonly property bool labelVisible: root.showLabels === "always"
        || (root.showLabels === "hover" && root.hovered)

    // Every state is carried by brightness alone: nothing moves, resizes, or
    // gains a background. A pinned application that is not running sits dim so
    // the strip reads like a command history where only live entries are lit,
    // and hovering one lifts it towards the running ones. Not readonly, because
    // Behavior needs to intercept the binding's writes to ease them.
    property color itemColor: {
        if (root.urgent) return Color.urgent
        if (root.localActive || root.pressed) return Color.accent
        if (root.running) return Color.bar.text
        return Util.alpha(Color.bar.text, root.hovered ? 0.9 : 0.4)
    }

    Behavior on itemColor {
        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    function hasLocalActiveWindow() {
        var windows = DockModel.toArray(root.itemRecord.windows)
        for (var index = 0; index < windows.length; index += 1) {
            var window = windows[index]
            if (!window || !window.active) continue
            if (!root.monitorName) return true
            if (window.monitorName === root.monitorName) return true
            if (DockModel.toArray(window.screenNames).indexOf(root.monitorName) >= 0) return true
        }
        return false
    }

    implicitWidth: itemRow.implicitWidth + itemPadding * 2
    implicitHeight: itemHeight
    width: implicitWidth
    height: implicitHeight

    Row {
        id: itemRow
        anchors.centerIn: parent
        spacing: Style.space(6)

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showSlotNumbers && root.slotLabel !== ""
            text: root.slotLabel
            color: Util.alpha(root.itemColor, 0.55)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
        }

        DockIcon {
            anchors.verticalCenter: parent.verticalCenter
            itemRecord: root.itemRecord
            glyphSize: root.glyphSize
            tint: root.itemColor
            useCuratedGlyphs: root.configuration.appearance
                && root.configuration.appearance.usePixelGlyphs !== false
        }

        DockLabel {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.labelVisible
            text: root.commandLabel
            color: root.itemColor
            font.family: Style.font.family
            font.pixelSize: Style.font.bodySmall
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.countLabel !== ""
            text: root.countLabel
            color: Util.alpha(root.itemColor, 0.6)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
        }
    }

    // Marker rule, on the same matrix as the glyphs. The run stays the same
    // length in every state and only its brightness changes, so focus reads as
    // the row lighting up rather than as the marker growing.
    DotMatrix {
        id: marker
        visible: root.running
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(3)
        pitch: root.markerPitch
        rows: 1
        columns: root.markerDots
        cells: PixelGlyphs.ruleCells(root.markerDots)
        tint: root.urgent ? Color.urgent
            : root.localActive ? Color.accent
            : Util.alpha(Color.bar.text, 0.35)

        Behavior on tint {
            ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: function(mouse) {
            root.pressed = true
            root.pressX = mouse.x
            root.pressY = mouse.y
            root.pressButton = mouse.button
            root.dragStarted = false
            root.suppressClick = false
        }
        onPositionChanged: function(mouse) {
            if (!pressed || root.pressButton !== Qt.LeftButton || !root.dockContent) return

            var point = root.mapToItem(root.dockContent, mouse.x, mouse.y)
            if (root.dragStarted) {
                root.dockContent.updateDrag(point.x)
                return
            }

            var dx = mouse.x - root.pressX
            var dy = mouse.y - root.pressY
            var distance = Math.sqrt(dx * dx + dy * dy)
            if (distance < root.dragThreshold) return
            if (root.dockContent.beginDrag(root.itemIndex, root.itemRecord)) {
                root.dragStarted = true
                root.suppressClick = true
                root.dockContent.updateDrag(point.x)
            }
        }
        onReleased: function(mouse) {
            var wasDragging = root.dragStarted
            if (wasDragging && root.dockContent) {
                var point = root.mapToItem(root.dockContent, mouse.x, mouse.y)
                root.dockContent.finishDrag(point.x)
            }
            root.dragStarted = false
            root.pressButton = Qt.NoButton
            root.pressed = false
        }
        onCanceled: {
            if (root.dragStarted && root.dockContent) root.dockContent.cancelDrag()
            root.dragStarted = false
            root.pressButton = Qt.NoButton
            root.pressed = false
        }
        onClicked: function(mouse) {
            if (root.suppressClick) {
                root.suppressClick = false
                return
            }
            if (!root.appService) return
            if (mouse.button === Qt.RightButton) {
                if (root.hasContextActions) root.contextMenuOpen = true
                return
            }

            var action = mouse.button === Qt.MiddleButton
                ? ActionModel.middleClickAction(root.configuration)
                : ActionModel.clickAction(root.configuration)
            ActionModel.performAction(action, root.appService, root.itemRecord, true)
        }

        // A touchpad reports a scroll gesture as a stream of small deltas. Acting
        // on each one cycles through every window of an application in a single
        // flick, so deltas are accumulated into discrete notches first.
        onWheel: function(wheel) {
            if (!root.appService || wheel.angleDelta.y === 0) return
            var action = ActionModel.wheelAction(root.configuration)
            if (action === "none") return

            root.wheelAccumulator += wheel.angleDelta.y
            while (Math.abs(root.wheelAccumulator) >= root.wheelNotch) {
                var forward = root.wheelAccumulator > 0
                root.wheelAccumulator += forward ? -root.wheelNotch : root.wheelNotch
                ActionModel.performAction(action, root.appService, root.itemRecord, forward)
            }
        }
    }

    onHoveredChanged: if (!root.hovered) root.wheelAccumulator = 0

    DockTooltip {
        targetItem: root
        targetWindow: root.dockWindow
        visible: root.hovered && !root.labelVisible && root.showLabels !== "never"
            && !root.contextMenuOpen
        label: {
            var count = root.itemRecord.windowCount || 0
            var suffix = count > 1 ? "  " + count + "x" : ""
            return (root.slotLabel !== "" ? root.slotLabel + "  " : "")
                + root.commandLabel + suffix
        }
    }

    DockContextMenu {
        targetItem: root
        targetWindow: root.dockWindow
        itemRecord: root.itemRecord
        appService: root.appService
        configService: root.configService
        requestedOpen: root.contextMenuOpen
        onMenuClosed: root.contextMenuOpen = false
    }

    onContextMenuOpenChanged: {
        if (root.hideController) {
            root.hideController.setHold(
                "menu", String(root.itemRecord.key || root.itemRecord.desktopId || "item"),
                root.contextMenuOpen
            )
        }
    }

    Component.onDestruction: {
        if (root.dockContent) root.dockContent.cancelDragIf(root.itemRecord)
        if (root.contextMenuOpen && root.hideController) {
            root.hideController.setHold(
                "menu", String(root.itemRecord.key || root.itemRecord.desktopId || "item"), false
            )
        }
    }
}
