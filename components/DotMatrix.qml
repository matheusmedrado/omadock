import QtQuick
import qs.Commons

// Lays out lit cells as discrete dots on a fixed pitch. Everything in the dock
// that is drawn as dots goes through here, so a glyph, the prompt, and the
// marker rules all share one dot size and gutter and read as the same matrix.
Item {
    id: root

    // Cells to light, as {row, column} pairs.
    property var cells: []
    property int columns: 7
    property int rows: 7
    property int pitch: 4
    property color tint: Color.bar.text
    // Fraction of the pitch a dot occupies; the remainder is the gutter that
    // keeps the matrix legible as dots rather than a filled shape.
    property real fill: 0.75

    readonly property real dotSize: Math.max(1, Math.round(pitch * fill))

    implicitWidth: columns * pitch
    implicitHeight: rows * pitch
    width: implicitWidth
    height: implicitHeight

    Repeater {
        model: root.cells

        delegate: Rectangle {
            required property var modelData
            // Centre each dot in its cell so the gutter is even on both sides.
            x: modelData.column * root.pitch + (root.pitch - root.dotSize) / 2
            y: modelData.row * root.pitch + (root.pitch - root.dotSize) / 2
            width: root.dotSize
            height: root.dotSize
            radius: width / 2
            color: root.tint
            antialiasing: true
        }
    }
}
