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
    // A globe with its graticule, for a site running as its own window. This is
    // deliberately not the browser ring: the browser is the program you launch,
    // a web application is one address pinned beside native ones, and a strip
    // that draws them identically has answered the wrong question.
    webapp: [
        "0011100",
        "0111110",
        "1010101",
        "1111111",
        "1010101",
        "0111110",
        "0011100"
    ],
    // A display over a keypad.
    calculator: [
        "1111111",
        "1000001",
        "1111111",
        "1010101",
        "1000001",
        "1010101",
        "1111111"
    ],
    // Ascending bars. A system monitor used to resolve to the settings gear,
    // which read as "a preferences panel" for what is actually a live graph.
    monitor: [
        "0000001",
        "0000101",
        "0000101",
        "0010101",
        "0010101",
        "1010101",
        "1010101"
    ],
    // Stacked platters, the long-standing shape for storage.
    disk: [
        "0111110",
        "1000001",
        "0111110",
        "1000001",
        "0111110",
        "1000001",
        "0111110"
    ],
    // A header band over ruled cells, so a spreadsheet is not the notepad its
    // `Office;` category used to earn it.
    spreadsheet: [
        "1111111",
        "1111111",
        "1001001",
        "1111111",
        "1001001",
        "1111111",
        "1001001"
    ],
    // A chart on a screen, over a stand.
    presentation: [
        "1111111",
        "1000001",
        "1000101",
        "1001101",
        "1011101",
        "1111111",
        "0011100"
    ],
    // A pin: a pierced head tapering to a point. The taper is what keeps it
    // apart from the browser and webapp rings at this size.
    map: [
        "0011100",
        "0111110",
        "1100011",
        "1100011",
        "0111110",
        "0011100",
        "0001000"
    ],
    // A camera body and its lens. A video call is not the speech bubble that
    // chat draws, and not the play triangle that video draws.
    call: [
        "0000000",
        "1111100",
        "1000110",
        "1000111",
        "1000110",
        "1111100",
        "0000000"
    ],
    // Head and shoulders.
    contacts: [
        "0011100",
        "0100010",
        "0100010",
        "0011100",
        "0000000",
        "0111110",
        "1111111"
    ],
    // A chest with a lid and a strap.
    archive: [
        "1111111",
        "1000001",
        "1111111",
        "1001001",
        "1001001",
        "1000001",
        "1111111"
    ],
    // An arrow onto a floor.
    download: [
        "0001000",
        "0001000",
        "1111111",
        "0111110",
        "0011100",
        "0001000",
        "1111111"
    ],
    // Body between a blank sheet going in and a printed one coming out. The
    // sheets are drawn differently on purpose: mirrored outlines read as a
    // symmetrical box rather than as a direction of travel.
    printer: [
        "0111110",
        "0100010",
        "1111111",
        "1000101",
        "1111111",
        "0111110",
        "0111110"
    ],
    // Vendor monograms. These are the marks for applications whose brand
    // reduces to a letterform or a simple geometric primitive, which is the only
    // kind of brand that survives a seven-dot grid.
    //
    // The rule is not negotiable artistically, it is a resolution limit, and it
    // was measured rather than assumed: drawn at the pitch the dock actually
    // renders, a Z, a hash and a V stay themselves, while a pictorial logo
    // collapses. Firefox's fox-on-globe and DBeaver's beaver both became
    // featureless lumps, and an attempt at Chrome's wheel came out as a ring
    // indistinguishable from the browser glyph beside it -- which would make the
    // strip less legible, not more. Those applications are better served by the
    // semantic glyph they already resolve to, so they deliberately have no
    // entry here. Anyone adding one should draw it at pitch 4 and look at it
    // before deciding it reads.
    zed: [
        "1111111",
        "0000110",
        "0001100",
        "0011000",
        "0110000",
        "1100000",
        "1111111"
    ],
    // The folded ribbon, which reads as a bar with a chevron tucked into it.
    vscode: [
        "0000110",
        "0010110",
        "0110110",
        "1100110",
        "0110110",
        "0010110",
        "0000110"
    ],
    neovim: [
        "1000001",
        "1000001",
        "0100010",
        "0100010",
        "0010100",
        "0010100",
        "0001000"
    ],
    // A text I-beam, for the editor named after one.
    cursor: [
        "1111111",
        "0011100",
        "0011100",
        "0011100",
        "0011100",
        "0011100",
        "1111111"
    ],
    // The pinwheel, which at this size is a hash.
    slack: [
        "0010100",
        "0010100",
        "1111111",
        "0010100",
        "1111111",
        "0010100",
        "0010100"
    ],
    discord: [
        "0011100",
        "0111110",
        "1111111",
        "1101011",
        "1111111",
        "0110110",
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
function cellsForBitmap(rows) {
    var cells = []
    for (var row = 0; row < rows.length; row += 1) {
        var line = String(rows[row])
        for (var column = 0; column < line.length; column += 1) {
            if (line.charAt(column) === "1") cells.push({ row: row, column: column })
        }
    }
    return cells
}

function cellsFor(key) {
    return cellsForBitmap(bitmapFor(key))
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


// Artwork for the bar widget. The dot size is a fraction of the pitch, so a
// matrix drawn too small rounds to a dot as wide as its own cell: the gutter
// disappears, the dots meet, and the glyph reads as a solid shape rather than as
// a matrix -- which is the one thing every mark in this plugin is supposed to
// read as. That sets the floor on the pitch, and the pitch times the cell count
// is what the bar actually paints.
//
// Three cells at pitch 4 paint 11px inside the bar's 16px optical canvas, which
// is the range its other icons occupy -- measured on a running bar, the
// neighbouring glyphs paint 9 to 12px tall. Five cells at pitch 3 painted 15px,
// which made this the tallest thing on the bar by a third.
//
// Three cells is a coarse grid, so the caller drops the dot to half the pitch
// rather than the three quarters the dock uses: adjacent lit cells are the norm
// here rather than the exception, and at three quarters the gutter between two
// dots closes and the chevron draws as a blob.
var BAR_SIZE = 3

var BAR_GLYPHS = {
    // The chevron that opens the dock's own strip, so the bar carries the same
    // mark as the prompt it toggles.
    //
    // Every cell of the grid is used, in both directions. The five-cell chevron
    // this replaces lit only columns 0 to 2, and since the matrix is centred as
    // a box rather than as its artwork, the mark hung 3px left of the icon slot
    // it sits in -- against a 27px slot pitch, far enough to see once the icons
    // beside it are evenly spaced. test_theBarGlyphIsCentredInItsGrid keeps it
    // honest.
    prompt: [
        "110",
        "011",
        "110"
    ]
}

function hasBar(key) {
    return Object.prototype.hasOwnProperty.call(BAR_GLYPHS, String(key || ""))
}

function barBitmapFor(key) {
    return hasBar(key) ? BAR_GLYPHS[key] : BAR_GLYPHS.prompt
}

function barCellsFor(key) {
    return cellsForBitmap(barBitmapFor(key))
}
