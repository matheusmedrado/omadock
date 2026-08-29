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
        for (var vendorId in GlyphModel.VENDOR) {
            verify(PixelGlyphs.has(GlyphModel.VENDOR[vendorId]),
                   "no artwork for vendor key " + GlyphModel.VENDOR[vendorId])
        }
        for (var index = 0; index < GlyphModel.KEYWORDS.length; index += 1) {
            var key = GlyphModel.KEYWORDS[index].glyph
            verify(PixelGlyphs.has(key), "no artwork for keyword key " + key)
        }
        for (var categoryIndex = 0;
                categoryIndex < GlyphModel.CATEGORY_GLYPHS.length;
                categoryIndex += 1) {
            var categoryKey = GlyphModel.CATEGORY_GLYPHS[categoryIndex].glyph
            verify(PixelGlyphs.has(categoryKey),
                   "no artwork for category key " + categoryKey)
        }
        for (var hostIndex = 0; hostIndex < GlyphModel.WEB_HOSTS.length; hostIndex += 1) {
            var hostKey = GlyphModel.WEB_HOSTS[hostIndex].glyph
            verify(PixelGlyphs.has(hostKey), "no artwork for web host key " + hostKey)
        }
        verify(PixelGlyphs.has(GlyphModel.WEBAPP_GLYPH))
    }

    // A table entry with no terms matches nothing and is dead weight that reads
    // as coverage. One was left behind while the web host table was being
    // written, naming a glyph that had no artwork either.
    function test_noResolutionTableEntryIsEmpty() {
        var tables = [GlyphModel.KEYWORDS, GlyphModel.CATEGORY_GLYPHS, GlyphModel.WEB_HOSTS]
        for (var tableIndex = 0; tableIndex < tables.length; tableIndex += 1) {
            var table = tables[tableIndex]
            for (var index = 0; index < table.length; index += 1) {
                verify(table[index].terms.length > 0,
                       "entry for " + table[index].glyph + " has no terms")
            }
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

    // The bar centres the matrix as a box rather than as its artwork, so a glyph
    // whose lit cells sit to one side hangs off-centre in its icon slot. The
    // five-cell chevron this replaced lit only columns 0 to 2 and drew 3px left
    // of where it belonged, against a 27px slot pitch.
    function test_theBarGlyphIsCentredInItsGrid() {
        for (var key in PixelGlyphs.BAR_GLYPHS) {
            var rows = PixelGlyphs.BAR_GLYPHS[key]
            compare(rows.length, PixelGlyphs.BAR_SIZE, key + " has the wrong row count")

            var minRow = -1
            var maxRow = -1
            var minColumn = PixelGlyphs.BAR_SIZE
            var maxColumn = -1
            for (var row = 0; row < rows.length; row += 1) {
                var line = String(rows[row])
                compare(line.length, PixelGlyphs.BAR_SIZE,
                        key + " row " + row + " is the wrong width")
                verify(/^[01]+$/.test(line),
                       key + " row " + row + " has a cell that is not 0 or 1")
                for (var column = 0; column < line.length; column += 1) {
                    if (line.charAt(column) !== "1") continue
                    if (minRow < 0) minRow = row
                    maxRow = row
                    if (column < minColumn) minColumn = column
                    if (column > maxColumn) maxColumn = column
                }
            }

            verify(maxRow >= 0, key + " has no lit cells")
            compare(minColumn, PixelGlyphs.BAR_SIZE - 1 - maxColumn,
                    key + " is not centred horizontally")
            compare(minRow, PixelGlyphs.BAR_SIZE - 1 - maxRow,
                    key + " is not centred vertically")
        }
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

    function test_columnCellsAreASingleColumn() {
        var cells = PixelGlyphs.columnCells(5)
        compare(cells.length, 5)
        for (var index = 0; index < cells.length; index += 1) {
            compare(cells[index].column, 0)
            compare(cells[index].row, index)
        }
        compare(PixelGlyphs.columnCells(0).length, 0)
        compare(PixelGlyphs.columnCells(-3).length, 0)
    }
}
