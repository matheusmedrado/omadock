import QtQuick
import qs.Commons
import "../models/ActionModel.js" as ActionModel
import "../models/DockModel.js" as DockModel

Item {
    id: root

    property var itemRecord: ({})
    property var configuration: ({})
    property var appService
    property var configService
    property string monitorName: ""
    property var dockWindow
    property bool hovered: false
    property bool pressed: false
    property bool contextMenuOpen: false

    readonly property var metrics: DockModel.surfaceMetrics(configuration)
    readonly property int itemSize: metrics.itemSize
    readonly property int iconSize: metrics.iconSize
    readonly property bool localActive: hasLocalActiveWindow()
    readonly property bool hasContextActions: ActionModel.actionsForItem(root.itemRecord).length > 0
    readonly property bool showSlotNumbers: configuration.appearance
        && configuration.appearance.showSlotNumbers !== false
    readonly property string showLabels: configuration.appearance && configuration.appearance.showLabels
        ? configuration.appearance.showLabels : "hover"
    readonly property bool usePixelGlyphs: configuration.appearance
        && configuration.appearance.usePixelGlyphs !== false

    function hasLocalActiveWindow() {
        var windows = Array.isArray(root.itemRecord.windows) ? root.itemRecord.windows : []
        for (var index = 0; index < windows.length; index += 1) {
            var window = windows[index]
            if (!window || !window.active) continue
            if (!root.monitorName) return true
            if (window.monitorName === root.monitorName) return true
            if (Array.isArray(window.screenNames)
                    && window.screenNames.indexOf(root.monitorName) >= 0) return true
        }
        return false
    }

    width: itemSize
    height: itemSize

    Rectangle {
        id: tile
        anchors.fill: parent
        radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 8) : 0
        color: root.pressed ? Color.accent : Color.bar.background
        border.color: root.itemRecord.urgent ? Color.urgent
            : root.localActive ? Color.accent : Color.muted
        border.width: 1
    }

    Text {
        id: slotNumber
        visible: root.showSlotNumbers && root.itemRecord.slot > 0
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: Style.space(4)
        anchors.topMargin: Style.space(2)
        text: root.itemRecord.slot > 0 ? ("0" + root.itemRecord.slot).slice(-2) : ""
        color: root.pressed ? Color.background : Color.bar.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
    }

    DockIcon {
        anchors.centerIn: parent
        itemRecord: root.itemRecord
        iconSize: root.iconSize
        usePixelGlyphs: root.usePixelGlyphs
    }

    DockLabel {
        visible: root.showLabels === "always"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Style.space(2)
        anchors.rightMargin: Style.space(2)
        anchors.bottomMargin: Style.space(2)
        text: root.itemRecord.shortLabel || "APP"
        color: root.pressed ? Color.background : Color.bar.text
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
    }

    Rectangle {
        visible: root.localActive
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Style.space(2)
        width: Style.space(10)
        height: Style.space(2)
        color: root.pressed ? Color.background : Color.accent
    }

    Rectangle {
        visible: !!root.itemRecord.urgent
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: Style.space(3)
        anchors.topMargin: Style.space(3)
        width: Style.space(5)
        height: width
        color: Color.urgent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true
        onReleased: root.pressed = false
        onCanceled: root.pressed = false
        onClicked: function(mouse) {
            if (!root.appService) return
            if (mouse.button === Qt.MiddleButton) root.appService.launchNew(root.itemRecord)
            else if (mouse.button === Qt.LeftButton) root.appService.focusOrLaunch(root.itemRecord)
            else if (mouse.button === Qt.RightButton && root.hasContextActions) root.contextMenuOpen = true
        }
        onWheel: function(wheel) {
            if (root.appService && wheel.angleDelta.y !== 0) root.appService.focusNext(root.itemRecord)
        }
    }

    DockTooltip {
        targetItem: root
        targetWindow: root.dockWindow
        visible: root.hovered && root.showLabels !== "never" && !root.contextMenuOpen
        label: {
            var count = root.itemRecord.windowCount || 0
            var suffix = count > 0 ? "  " + count + "x" : ""
            return (root.itemRecord.slot > 0 ? ("0" + root.itemRecord.slot).slice(-2) + "  " : "")
                + (root.itemRecord.shortLabel || "APP") + suffix
        }
    }

    DockContextMenu {
        targetItem: root
        targetWindow: root.dockWindow
        itemRecord: root.itemRecord
        appService: root.appService
        configService: root.configService
        requestedOpen: root.contextMenuOpen
        onClosed: root.contextMenuOpen = false
    }
}
