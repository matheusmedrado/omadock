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

    // The source slot is a placeholder while dragging. Once the drop would
    // unpin rather than reorder, it fades most of the way out so the gesture
    // reads as removal before the button is released.
    readonly property bool dragRemoving: root.dragSource && !!root.dockContent
        && root.dockContent.dragWillRemove
    opacity: root.dragRemoving ? 0.12 : root.dragSource ? 0.4 : 1

    Behavior on opacity {
        NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
    }

    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemHeight: metrics.itemHeight
    readonly property int glyphSize: metrics.glyphSize
    readonly property int itemPadding: metrics.itemPadding
    readonly property int labelRevealMs: DockModel.labelRevealMs(configuration)
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

    // Brightness is the whole state system, so it runs as a ladder with the
    // application you are actually on at the top: focused, then running, then
    // pinned but not running. Hovering lifts an entry one step, which every
    // entry except the focused one has room for -- that one is already at the
    // top and stays put.
    //
    // The ladder is built from the text colour, not the accent. A theme's accent
    // is frequently darker than its foreground (Omarchy's default ships #798186
    // against #cacccc), so colouring the focused entry with it would place the
    // one you are on *below* its neighbours. Accent stays on the marker, where it
    // tags the focused entry without having to carry brightness.
    readonly property real stateAlpha: {
        // An urgent entry sits at the top of the ladder whether or not it is
        // running: its glyph carries the colour, so the label has to stay at
        // full brightness to be worth reading.
        if (root.urgent) return 1.0
        // Press dips rather than sharing the focused rung. Clicking the
        // application you are already on used to produce no feedback at all,
        // because focused and pressed were the same value.
        if (root.pressed) return 0.72
        if (root.localActive) return 1.0
        if (root.running) return root.hovered ? 0.85 : 0.62
        return root.hovered ? 0.62 : 0.32
    }

    // Not readonly: Behavior has to intercept the binding's writes to ease them.
    property color itemColor: Util.alpha(Color.bar.text, root.stateAlpha)

    // Urgent is carried by the glyph and the marker, not by the label. Repainting
    // the label too dropped a red word into a row of readable ones, which is
    // harder to read and no more noticeable against this palette.
    property color glyphColor: root.urgent ? Color.urgent : root.itemColor

    Behavior on itemColor {
        ColorAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    Behavior on glyphColor {
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
        // The gaps are carried by the children rather than by the row. The hover
        // label animates its own width down to nothing, and a row spacing would
        // survive that and leave its gap behind as dead space beside a label
        // that is no longer there.
        spacing: 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showSlotNumbers && root.slotLabel !== ""
            rightPadding: Style.space(6)
            text: root.slotLabel
            color: Util.alpha(root.itemColor, 0.55)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
        }

        DockIcon {
            id: glyphIcon
            anchors.verticalCenter: parent.verticalCenter
            itemRecord: root.itemRecord
            glyphSize: root.glyphSize
            tint: root.glyphColor
            useCuratedGlyphs: root.configuration.appearance
                && root.configuration.appearance.usePixelGlyphs !== false
        }

        // On hover the label used to appear at its full width in one frame, which
        // pushed every entry after it sideways in the same frame. Reading the
        // strip meant crossing several entries, so a single sweep re-laid the row
        // out once per entry and the whole thing juddered under the pointer.
        //
        // Opening the slot over time fixes more than the jitter: crossing from
        // one entry to the next now closes one label while it opens the other, so
        // the row's total width barely moves and its neighbours hold still.
        Item {
            id: labelSlot
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showLabels !== "never"
            clip: true
            implicitHeight: label.implicitHeight
            width: root.labelVisible ? Style.space(6) + label.implicitWidth : 0

            Behavior on width {
                NumberAnimation {
                    duration: root.labelRevealMs
                    easing.type: Easing.OutCubic
                }
            }

            DockLabel {
                id: label
                x: Style.space(6)
                anchors.verticalCenter: parent.verticalCenter
                text: root.commandLabel
                color: root.itemColor
                font.family: Style.font.family
                font.pixelSize: Style.font.bodySmall
                opacity: root.labelVisible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.labelRevealMs
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.countLabel !== ""
            leftPadding: Style.space(6)
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
        // Centred on the glyph rather than on the item: the item is as wide as
        // its label, so on a long one the rule drifted out from under the mark it
        // belongs to and the strip lost its baseline. The glyph is not a sibling
        // (it lives inside the row), so this is an x rather than an anchor, and
        // it stays correct when showSlotNumbers puts a number ahead of it.
        x: itemRow.x + glyphIcon.x + glyphIcon.width / 2 - width / 2
        anchors.bottom: parent.bottom
        // A cell and a half below the glyph's last row. Deliberately off the
        // matrix, and the only mark here that is: a single cell puts the
        // matrix's own gutter between them, which is the right amount *inside* a
        // glyph and too tight between two separate marks -- the rule reads as
        // another row of the glyph rather than as a thing beneath it. Two cells
        // is on the grid again but sinks the rule toward the dither gathered
        // along the bottom edge, where a running application's rule at 0.32 has
        // to stay legible. Half a cell is the difference between the two.
        //
        // Clamped so the extreme icon sizes cannot push it out through the
        // surface below.
        anchors.bottomMargin: Math.max(
            -(root.metrics.contentPadding - 1),
            Math.round((root.itemHeight - root.glyphSize) / 2)
                - Math.round(root.markerPitch * 1.5))
        pitch: root.markerPitch
        rows: 1
        columns: root.markerDots
        cells: PixelGlyphs.ruleCells(root.markerDots)
        tint: root.urgent ? Color.urgent
            : root.localActive ? Color.accent
            : Util.alpha(Color.bar.text, root.hovered ? 0.6 : 0.32)

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
                root.dockContent.updateDrag(point.x, point.y)
                return
            }

            var dx = mouse.x - root.pressX
            var dy = mouse.y - root.pressY
            var distance = Math.sqrt(dx * dx + dy * dy)
            if (distance < root.dragThreshold) return
            if (root.dockContent.beginDrag(root.itemIndex, root.itemRecord)) {
                root.dragStarted = true
                root.suppressClick = true
                root.dockContent.updateDrag(point.x, point.y)
            }
        }
        onReleased: function(mouse) {
            var wasDragging = root.dragStarted
            if (wasDragging && root.dockContent) {
                var point = root.mapToItem(root.dockContent, mouse.x, mouse.y)
                root.dockContent.finishDrag(point.x, point.y)
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
