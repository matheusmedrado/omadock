import QtQuick
import qs.Commons

// An ordered-dither fill. Coverage is decided per cell by comparing a vertical
// ramp against a Bayer threshold matrix, which is how a 1-bit display fakes a
// gradient: no cell is ever partly lit, the density of lit cells carries the
// tone. That is the whole point of the effect here, so the cells are drawn
// several pixels wide. A one-pixel dither reads as noise; a chunky one reads as
// a deliberate texture.
//
// The pattern is static, so it is painted once and repainted only when its
// geometry, colour, or ramp changes.
Canvas {
    id: root

    property color tint: Color.bar.text
    property int cell: 2
    // Coverage at the top and bottom edges, 0 to 1. The default fades downwards
    // so the strip sits into the screen edge rather than floating on it.
    property real topCoverage: 0.0
    property real bottomCoverage: 0.55
    property real gamma: 1.0

    readonly property var bayer: [
        [0, 8, 2, 10],
        [12, 4, 14, 6],
        [3, 11, 1, 9],
        [15, 7, 13, 5]
    ]

    onTintChanged: requestPaint()
    onCellChanged: requestPaint()
    onTopCoverageChanged: requestPaint()
    onBottomCoverageChanged: requestPaint()
    onGammaChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        if (width <= 0 || height <= 0) return

        var step = Math.max(1, root.cell)
        var columns = Math.ceil(width / step)
        var rows = Math.ceil(height / step)
        if (rows <= 0 || columns <= 0) return

        ctx.fillStyle = root.tint

        for (var row = 0; row < rows; row += 1) {
            // Ramp position of this row, 0 at the top edge and 1 at the bottom.
            var position = rows === 1 ? 1 : row / (rows - 1)
            if (root.gamma !== 1.0) position = Math.pow(position, root.gamma)

            var coverage = root.topCoverage + (root.bottomCoverage - root.topCoverage) * position
            if (coverage <= 0) continue

            for (var column = 0; column < columns; column += 1) {
                // Bayer thresholds are 0..15; +0.5 centres each level inside its
                // band so full coverage lights every cell and zero lights none.
                var threshold = (root.bayer[row % 4][column % 4] + 0.5) / 16
                if (coverage <= threshold) continue
                ctx.fillRect(column * step, row * step, step, step)
            }
        }
    }
}
