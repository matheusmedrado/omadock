import QtQuick
import qs.Commons
import "../models/GlyphModel.js" as GlyphModel
import "../models/PixelGlyphs.js" as PixelGlyphs

// An application glyph on the dot matrix, or the application's own icon when
// curated glyphs are turned off.
Item {
    id: root

    property var itemRecord: ({})
    property int glyphSize: 28
    property color tint: Color.bar.text
    property bool useCuratedGlyphs: true

    readonly property string glyphKey: GlyphModel.glyphFor(
        root.itemRecord.desktopId, root.itemRecord.appId, root.itemRecord.name)
    readonly property bool useImage: !root.useCuratedGlyphs && !!root.itemRecord.iconSource

    // Whole-pixel pitch: a fractional one lands some dots a subpixel off and the
    // matrix stops looking regular.
    readonly property int pitch: Math.max(2, Math.floor(glyphSize / PixelGlyphs.SIZE))

    implicitWidth: matrix.implicitWidth
    implicitHeight: matrix.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Image {
        anchors.fill: parent
        visible: root.useImage
        source: root.useImage ? root.itemRecord.iconSource : ""
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    DotMatrix {
        id: matrix
        visible: !root.useImage
        cells: root.useImage ? [] : PixelGlyphs.cellsFor(root.glyphKey)
        columns: PixelGlyphs.SIZE
        rows: PixelGlyphs.SIZE
        pitch: root.pitch
        tint: root.tint
    }
}
