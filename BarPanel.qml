import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Commons
import qs.Ui
import "components"
import "models/PixelGlyphs.js" as PixelGlyphs
import "services"

// Dock preferences, reachable from the bar. The panel writes through the same
// ConfigService the dock itself uses, so every change takes the same validation
// and atomic write as one typed into config.json by hand, and the running dock
// picks it up from its own file watcher without a restart.
Panel {
    id: root

    moduleName: "io.github.matheusmedrado.omadock"
    ipcTarget: "omadock-settings"

    property var shell
    property var manifest
    property var pluginRegistry
    property string omarchyPath: ""

    readonly property var configuration: configService.settings
    readonly property var appearance: configuration && configuration.appearance
        ? configuration.appearance : ({})
    readonly property var behavior: configuration && configuration.behavior
        ? configuration.behavior : ({})

    readonly property color foreground: bar ? bar.foreground : Color.foreground
    readonly property color dim: Util.alpha(foreground, 0.55)
    readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    ConfigService {
        id: configService
    }

    function setAppearance(key, value) { configService.setSectionValue("appearance", key, value) }
    function setBehavior(key, value) { configService.setSectionValue("behavior", key, value) }

    function appearanceValue(key, fallback) {
        var value = root.appearance[key]
        return value === undefined || value === null ? fallback : value
    }

    function behaviorValue(key, fallback) {
        var value = root.behavior[key]
        return value === undefined || value === null ? fallback : value
    }

    // ---------------------------------------------------------------- rows
    //
    // The dock's own language is dots and monospace, but a preferences list
    // needs to be scanned and read, so the controls are the shell's standard
    // ones. The dock's identity shows up where it does not cost legibility:
    // the bar glyph, the dithered header, and the monospace readouts.

    component Header: Item {
        property string text: ""
        width: parent ? parent.width : 0
        implicitHeight: Style.space(26)

        PanelSectionHeader {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Style.space(4)
            text: parent.text
            foreground: root.foreground
            fontFamily: root.fontFamily
        }
    }

    component SwitchRow: Item {
        property string label: ""
        property string description: ""
        property bool checked: false
        signal toggled(bool value)

        width: parent ? parent.width : 0
        implicitHeight: control.implicitHeight

        Toggle {
            id: control
            width: parent.width
            label: parent.label
            description: parent.description
            checked: parent.checked
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: parent.toggled(!parent.checked)
        }
    }

    // Segments rather than a dropdown. A dropdown opens a popup outside this
    // panel, and the panel dismisses on a click outside it, so selecting an
    // option closed the panel and threw the selection away. Options here are
    // few and short, so laying them out inline is both more robust and quicker
    // to read -- and selection can use the same brightness ladder as the dock.
    component ChoiceRow: Item {
        id: choice
        property string label: ""
        property string value: ""
        property string description: ""
        property var options: []
        signal picked(string value)

        width: parent ? parent.width : 0
        implicitHeight: title.implicitHeight + Style.space(5) + segments.implicitHeight
            + (caption.visible ? Style.space(4) + caption.implicitHeight : 0)

        Text {
            id: title
            anchors.top: parent.top
            anchors.left: parent.left
            text: choice.label
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
        }

        Flow {
            id: segments
            anchors.top: title.bottom
            anchors.topMargin: Style.space(5)
            width: parent.width
            spacing: Style.space(4)

            Repeater {
                model: choice.options

                delegate: Rectangle {
                    required property var modelData
                    readonly property string optionValue: modelData && typeof modelData === "object"
                        ? String(modelData.value) : String(modelData)
                    readonly property string optionLabel: modelData && typeof modelData === "object"
                        ? String(modelData.label) : String(modelData)
                    readonly property bool selected: optionValue === choice.value

                    implicitWidth: segmentLabel.implicitWidth + Style.space(18)
                    implicitHeight: Math.round(Style.spacing.controlHeight * 0.86)
                    radius: Style.cornerRadius > 0 ? Math.min(Style.cornerRadius, 6) : 0
                    color: selected ? Util.alpha(root.foreground, 0.13)
                        : segmentHover.containsMouse ? Util.alpha(root.foreground, 0.06)
                        : "transparent"
                    border.width: 1
                    border.color: selected ? Util.alpha(root.foreground, 0.5)
                        : Util.alpha(root.foreground, 0.18)

                    Text {
                        id: segmentLabel
                        anchors.centerIn: parent
                        text: parent.optionLabel
                        color: parent.selected ? root.foreground
                            : segmentHover.containsMouse ? Util.alpha(root.foreground, 0.85)
                            : root.dim
                        font.family: root.fontFamily
                        font.pixelSize: Style.font.bodySmall
                    }

                    MouseArea {
                        id: segmentHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: choice.picked(parent.optionValue)
                    }
                }
            }
        }

        Text {
            id: caption
            anchors.top: segments.bottom
            anchors.topMargin: Style.space(4)
            width: parent.width
            visible: choice.description !== ""
            text: choice.description
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
        }
    }

    component RangeRow: Item {
        property string label: ""
        property real value: 0
        property real minimum: 0
        property real maximum: 1
        property real step: 1
        property bool integer: true
        property string suffix: ""
        signal moved(real value)

        width: parent ? parent.width : 0
        implicitHeight: caption.implicitHeight + slider.implicitHeight + Style.space(8)

        Text {
            id: caption
            anchors.top: parent.top
            anchors.left: parent.left
            text: parent.label
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
        }

        // Monospace readout, so the numbers do not shift as they change.
        Text {
            anchors.top: parent.top
            anchors.right: parent.right
            text: (parent.integer ? Math.round(slider.liveValue)
                : Math.round(slider.liveValue * 100) / 100) + parent.suffix
            color: root.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
        }

        PanelSlider {
            id: slider
            anchors.bottom: parent.bottom
            width: parent.width
            bar: root.bar
            minimum: parent.minimum
            maximum: parent.maximum
            step: parent.step
            integer: parent.integer
            value: parent.value
            onMoved: function(next) { parent.moved(next) }
        }
    }

    // ---------------------------------------------------------------- bar

    BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        active: root.opened
        tooltipText: "Dock preferences"
        iconComponent: Component {
            Item {
                DotMatrix {
                    anchors.centerIn: parent
                    cells: PixelGlyphs.cellsFor("dock")
                    columns: PixelGlyphs.SIZE
                    rows: PixelGlyphs.SIZE
                    pitch: Math.max(2, Math.round(Style.space(12) / PixelGlyphs.SIZE))
                    tint: root.barForeground
                }
            }
        }
        onPressed: function(buttonCode) {
            if (buttonCode === Qt.MiddleButton) root.setBehavior("hideMode",
                root.behaviorValue("hideMode", "smart") === "never" ? "smart" : "never")
            else root.toggle()
        }
    }

    // ---------------------------------------------------------------- panel

    KeyboardPanel {
        id: panel
        anchorItem: button
        owner: root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(380))
        contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(600))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function(direction) { root.switchPanel(direction) }

            Flickable {
                id: flick
                anchors.fill: parent
                contentWidth: width
                contentHeight: column.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                Column {
                    id: column
                    width: flick.width
                    spacing: Style.space(10)

                    // The dock's own glyph and texture, so the panel is
                    // recognisably part of the same thing.
                    Item {
                        width: parent.width
                        height: Style.space(30)

                        DitherPattern {
                            anchors.fill: parent
                            cell: 2
                            tint: root.foreground
                            topCoverage: 0.0
                            bottomCoverage: 0.45
                            gamma: 2.2
                            opacity: 0.13
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Style.space(7)

                            DotMatrix {
                                anchors.verticalCenter: parent.verticalCenter
                                cells: PixelGlyphs.cellsFor("dock")
                                columns: PixelGlyphs.SIZE
                                rows: PixelGlyphs.SIZE
                                pitch: 2
                                tint: root.foreground
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "omadock"
                                color: root.foreground
                                font.family: Style.font.family
                                font.pixelSize: Style.font.body
                            }
                        }
                    }

                    Header { text: "BEHAVIOUR" }

                    ChoiceRow {
                        label: "Hide"
                        value: root.behaviorValue("hideMode", "smart")
                        options: [
                            { label: "Smart", value: "smart" },
                            { label: "Always hide", value: "always" },
                            { label: "Never hide", value: "never" }
                        ]
                        description: {
                            var mode = root.behaviorValue("hideMode", "smart")
                            if (mode === "always") return "Stay hidden; reveal from the screen edge."
                            if (mode === "never") return "Always on screen."
                            return "Hide only when a window would sit under the dock."
                        }
                        onPicked: function(next) { root.setBehavior("hideMode", next) }
                    }

                    SwitchRow {
                        label: "Reserve space"
                        description: root.behaviorValue("hideMode", "smart") === "never"
                            ? "Keep windows clear of the dock."
                            : "Push windows up while the dock is on screen, and give the space back when it hides."
                        checked: root.behaviorValue("reserveSpace", false)
                        onToggled: function(value) { root.setBehavior("reserveSpace", value) }
                    }

                    SwitchRow {
                        label: "Show running applications"
                        description: "List running applications that are not pinned."
                        checked: root.behaviorValue("showRunningUnpinned", true)
                        onToggled: function(value) { root.setBehavior("showRunningUnpinned", value) }
                    }

                    Header { text: "APPEARANCE" }

                    ChoiceRow {
                        label: "Density"
                        value: root.appearanceValue("density", "compact")
                        options: [
                            { label: "Compact", value: "compact" },
                            { label: "Comfortable", value: "comfortable" }
                        ]
                        onPicked: function(next) { root.setAppearance("density", next) }
                    }

                    ChoiceRow {
                        label: "Labels"
                        value: root.appearanceValue("showLabels", "always")
                        options: [
                            { label: "Always", value: "always" },
                            { label: "On hover", value: "hover" },
                            { label: "Never", value: "never" }
                        ]
                        onPicked: function(next) { root.setAppearance("showLabels", next) }
                    }

                    RangeRow {
                        label: "Glyph size"
                        value: root.appearanceValue("iconSize", 28)
                        minimum: 14
                        maximum: 42
                        step: 1
                        suffix: "px"
                        onMoved: function(next) { root.setAppearance("iconSize", Math.round(next)) }
                    }

                    RangeRow {
                        label: "Row height"
                        value: root.appearanceValue("itemSize", 40)
                        minimum: root.appearanceValue("iconSize", 28) + 8
                        maximum: 72
                        step: 1
                        suffix: "px"
                        onMoved: function(next) { root.setAppearance("itemSize", Math.round(next)) }
                    }

                    RangeRow {
                        label: "Edge margin"
                        value: root.appearanceValue("edgeMargin", 8)
                        minimum: 0
                        maximum: 32
                        step: 1
                        suffix: "px"
                        onMoved: function(next) { root.setAppearance("edgeMargin", Math.round(next)) }
                    }

                    RangeRow {
                        label: "Background opacity"
                        value: root.appearanceValue("backgroundOpacity", 1.0)
                        minimum: 0.35
                        maximum: 1.0
                        step: 0.01
                        integer: false
                        onMoved: function(next) { root.setAppearance("backgroundOpacity", next) }
                    }

                    Header { text: "MATRIX" }

                    SwitchRow {
                        label: "Dot-matrix glyphs"
                        description: "Off uses each application's own icon instead."
                        checked: root.appearanceValue("usePixelGlyphs", true)
                        onToggled: function(value) { root.setAppearance("usePixelGlyphs", value) }
                    }

                    SwitchRow {
                        label: "Dither texture"
                        checked: root.appearanceValue("showDither", true)
                        onToggled: function(value) { root.setAppearance("showDither", value) }
                    }

                    RangeRow {
                        label: "Dither cell"
                        value: root.appearanceValue("ditherCell", 2)
                        minimum: 1
                        maximum: 6
                        step: 1
                        suffix: "px"
                        enabled: root.appearanceValue("showDither", true)
                        opacity: enabled ? 1 : 0.4
                        onMoved: function(next) { root.setAppearance("ditherCell", Math.round(next)) }
                    }

                    SwitchRow {
                        label: "Prompt"
                        checked: root.appearanceValue("showPrompt", true)
                        onToggled: function(value) { root.setAppearance("showPrompt", value) }
                    }

                    SwitchRow {
                        label: "Slot numbers"
                        checked: root.appearanceValue("showSlotNumbers", false)
                        onToggled: function(value) { root.setAppearance("showSlotNumbers", value) }
                    }

                    Header { text: "POINTER" }

                    ChoiceRow {
                        label: "Click"
                        value: root.behaviorValue("clickAction", "focus-or-launch")
                        options: [
                            { label: "Focus or launch", value: "focus-or-launch" },
                            { label: "Focus only", value: "focus-only" },
                            { label: "Open new instance", value: "launch-new" },
                            { label: "Cycle windows", value: "cycle-windows" },
                            { label: "Nothing", value: "none" }
                        ]
                        onPicked: function(next) { root.setBehavior("clickAction", next) }
                    }

                    ChoiceRow {
                        label: "Middle click"
                        value: root.behaviorValue("middleClickAction", "launch-new")
                        options: [
                            { label: "Open new instance", value: "launch-new" },
                            { label: "Focus or launch", value: "focus-or-launch" },
                            { label: "Close active window", value: "close-active" },
                            { label: "Nothing", value: "none" }
                        ]
                        onPicked: function(next) { root.setBehavior("middleClickAction", next) }
                    }

                    ChoiceRow {
                        label: "Wheel"
                        value: root.behaviorValue("wheelAction", "cycle-windows")
                        options: [
                            { label: "Cycle windows", value: "cycle-windows" },
                            { label: "Nothing", value: "none" }
                        ]
                        onPicked: function(next) { root.setBehavior("wheelAction", next) }
                    }

                    Item {
                        width: parent.width
                        height: Style.space(18)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            text: "Pinned applications are managed from the dock itself. "
                                + "Everything here lives in ~/.config/omadock/config.json."
                            color: root.dim
                            font.family: Style.font.family
                            font.pixelSize: Style.font.caption
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }
        }
    }
}
