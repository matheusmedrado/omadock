import QtTest
import "../models/PixelGlyphs.js" as PixelGlyphs
import "../models/GlyphModel.js" as GlyphModel

TestCase {
    name: "PixelGlyphs"

    function test_everyGlyphIsASquareBitmapOfLitAndUnlitCells() {
        for (var key in PixelGlyphs.GLYPHS) {
            var rows = PixelGlyphs.GLYPHS[key]
            compare(rows.length, PixelGlyphs.SIZE, key + " has the wrong row count")
            for (var row = 0; row < rows.length; row += 1) {
                var line = String(rows[row])
                compare(line.length, PixelGlyphs.SIZE, key + " row " + row + " is the wrong width")
                verify(/^[01]+$/.test(line), key + " row " + row + " has a cell that is not 0 or 1")
            }
        }
    }

    // Every key GlyphModel can resolve to must have artwork, or an application
    // would match a category and then render as the fallback window glyph.
    function test_everyResolvableKeyHasArtwork() {
        verify(PixelGlyphs.has(GlyphModel.DEFAULT_GLYPH))
        for (var id in GlyphModel.EXACT) {
            verify(PixelGlyphs.has(GlyphModel.EXACT[id]),
                   "no artwork for exact key " + GlyphModel.EXACT[id])
        }
        for (var index = 0; index < GlyphModel.KEYWORDS.length; index += 1) {
            var key = GlyphModel.KEYWORDS[index].glyph
            verify(PixelGlyphs.has(key), "no artwork for keyword key " + key)
        }
    }

    function test_cellsListOnlyLitPositions() {
        var cells = PixelGlyphs.cellsFor("window")
        var rows = PixelGlyphs.bitmapFor("window")
        for (var index = 0; index < cells.length; index += 1) {
            var cell = cells[index]
            compare(String(rows[cell.row]).charAt(cell.column), "1")
        }

        var lit = 0
        for (var row = 0; row < rows.length; row += 1) {
            lit += String(rows[row]).split("1").length - 1
        }
        compare(cells.length, lit)
    }

    function test_unknownKeyFallsBackToTheWindowGlyph() {
        compare(PixelGlyphs.bitmapFor("no-such-glyph"), PixelGlyphs.GLYPHS.window)
        compare(PixelGlyphs.has("no-such-glyph"), false)
    }

    function test_ruleCellsAreASingleRow() {
        var cells = PixelGlyphs.ruleCells(4)
        compare(cells.length, 4)
        for (var index = 0; index < cells.length; index += 1) {
            compare(cells[index].row, 0)
            compare(cells[index].column, index)
        }
        compare(PixelGlyphs.ruleCells(0).length, 0)
        compare(PixelGlyphs.ruleCells(-3).length, 0)
    }
}
