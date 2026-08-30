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

    // One pixel of gutter is reserved before the fraction is honoured, because
    // rounding eats it first at a small pitch: at pitch 2 three quarters rounds
    // to 2, the dot becomes as wide as its own cell, and the matrix draws as a
    // filled shape -- the one thing every mark in this plugin is not supposed to
    // be. That has now been shipped twice, in the bar icon and in the panel
    // masthead, and it was still reachable from the dock itself, where any glyph
    // size below 21 lands on pitch 2 and drew every glyph solid. Clamping here
    // fixes all three at once and keeps a caller from finding a fourth: the
    // fraction still decides the dot everywhere it can be honoured, so no
    // existing size changes.
    readonly property real dotSize: Math.max(1, Math.min(pitch - 1,
                                                         Math.round(pitch * fill)))

    implicitWidth: columns * pitch
    implicitHeight: rows * pitch
    width: implicitWidth
    height: implicitHeight

    Repeater {
        model: root.cells

        delegate: Rectangle {
            required property var modelData
            // Centre each dot in its cell so the gutter is even on both sides,
            // rounded to a whole pixel. An odd remainder puts the dot on a half
            // pixel, which a circle hides but a 1px square cannot: it straddles
            // two columns at partial coverage and the smallest glyphs blur. The
            // offset is the same in every cell either way, so the matrix stays
            // regular.
            x: modelData.column * root.pitch + Math.round((root.pitch - root.dotSize) / 2)
            y: modelData.row * root.pitch + Math.round((root.pitch - root.dotSize) / 2)
            width: root.dotSize
            height: root.dotSize
            // A single-pixel dot is a pixel, not a circle. Rounding it and
            // antialiasing it spreads that one pixel over its neighbours and
            // leaves a smudge dimmer than the mark beside it, so at the
            // smallest glyph sizes the matrix reads as grey haze rather than as
            // dots. Above one pixel the circle is what makes it a dot matrix
            // rather than a grid of squares, so it keeps both.
            radius: width > 1 ? width / 2 : 0
            color: root.tint
            antialiasing: width > 1
        }
    }
}
