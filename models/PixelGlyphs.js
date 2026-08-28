.pragma library

// Dot-matrix glyphs, drawn as a 7x7 bitmap and rendered as discrete dots rather
// than strokes. This is the same idea as a dot-matrix display: shapes are
// implied by which cells are lit, so the glyph carries the dithered, low-
// resolution character of the rest of the dock instead of sitting next to it as
// smooth vector art.
//
// Each glyph is seven strings of seven characters. "1" lights the cell. Keeping
// them as text makes the artwork editable in place - the shape you read in the
// source is the shape that renders.

var SIZE = 7

var GLYPHS = {
    // A framed prompt: box outline with a chevron inside.
    terminal: [
        "0111110",
        "1000001",
        "1010001",
        "1001001",
        "1010001",
        "1000001",
        "0111110"
    ],
    // Ring with a lit core.
    browser: [
        "0011100",
        "0100010",
        "1000001",
        "1001001",
        "1000001",
        "0100010",
        "0011100"
    ],
    folder: [
        "0000000",
        "1110000",
        "1111110",
        "1000010",
        "1000010",
        "1111110",
        "0000000"
    ],
    // Angle brackets facing outwards.
    code: [
        "0000000",
        "0010100",
        "0101010",
        "1000001",
        "0101010",
        "0010100",
        "0000000"
    ],
    music: [
        "0000110",
        "0000110",
        "0000110",
        "0000110",
        "0110110",
        "1111110",
        "0111100"
    ],
    video: [
        "0000000",
        "0110000",
        "0111100",
        "0111111",
        "0111100",
        "0110000",
        "0000000"
    ],
    chat: [
        "0111110",
        "1000001",
        "1000001",
        "1000001",
        "0111111",
        "0001100",
        "0011000"
    ],
    notes: [
        "1111100",
        "1000110",
        "1000101",
        "1011101",
        "1000001",
        "1011101",
        "1111111"
    ],
    game: [
        "0000000",
        "1011101",
        "1111111",
        "1101011",
        "1111111",
        "1000001",
        "0000000"
    ],
    image: [
        "1111111",
        "1000001",
        "1010001",
        "1000001",
        "1001010",
        "1010101",
        "1111111"
    ],
    mail: [
        "1111111",
        "1100011",
        "1010101",
        "1001001",
        "1000001",
        "1000001",
        "1111111"
    ],
    container: [
        "0000000",
        "0011100",
        "0011100",
        "1111111",
        "1111111",
        "1111111",
        "0000000"
    ],
    settings: [
        "0010100",
        "1111111",
        "0111110",
        "1101011",
        "0111110",
        "1111111",
        "0010100"
    ],
    clipboard: [
        "0011100",
        "1111111",
        "1000001",
        "1011101",
        "1000001",
        "1011101",
        "1111111"
    ],
    shell: [
        "1111111",
        "1000001",
        "1011101",
        "1010101",
        "1011101",
        "1000001",
        "1111111"
    ],
    // The dock itself: a strip with three lit slots. Used by the bar widget.
    dock: [
        "0000000",
        "0000000",
        "1111111",
        "1000001",
        "1010101",
        "1111111",
        "0000000"
    ],
    // The shell prompt that opens the strip.
    prompt: [
        "0000000",
        "0110000",
        "0011000",
        "0001100",
        "0011000",
        "0110000",
        "0000000"
    ],
    // Fallback: a title bar over an empty body, i.e. an unidentified window.
    window: [
        "1111111",
        "1111111",
        "1000001",
        "1000001",
        "1000001",
        "1000001",
        "1111111"
    ]
}

function has(key) {
    return Object.prototype.hasOwnProperty.call(GLYPHS, String(key || ""))
}

function bitmapFor(key) {
    return has(key) ? GLYPHS[key] : GLYPHS.window
}

// Lit cells as {row, column} pairs, which is the form a delegate wants: one
// entry per dot, so nothing has to be laid out for a cell that stays dark.
function cellsFor(key) {
    var rows = bitmapFor(key)
    var cells = []
    for (var row = 0; row < rows.length; row += 1) {
        var line = String(rows[row])
        for (var column = 0; column < line.length; column += 1) {
            if (line.charAt(column) === "1") cells.push({ row: row, column: column })
        }
    }
    return cells
}

// A horizontal run of dots, used for the marker rules under an application so
// they sit on the same matrix as the glyphs rather than being solid bars.
function ruleCells(count) {
    var cells = []
    var total = Math.max(0, Math.floor(Number(count) || 0))
    for (var column = 0; column < total; column += 1) cells.push({ row: 0, column: column })
    return cells
}

// A vertical run of dots. The group divider and the drag insertion marker were
// both solid shapes drawn straight into the strip; this is what puts them on the
// same matrix as everything else.
function columnCells(count) {
    var cells = []
    var total = Math.max(0, Math.floor(Number(count) || 0))
    for (var row = 0; row < total; row += 1) cells.push({ row: row, column: 0 })
    return cells
}
