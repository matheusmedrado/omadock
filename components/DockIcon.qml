import QtQuick
import qs.Commons
import "../models/DockModel.js" as DockModel
import "../models/GlyphModel.js" as GlyphModel

Item {
    id: root

    property var itemRecord: ({})
    property int glyphSize: 16
    property color tint: Color.bar.text
    property bool useCuratedGlyphs: true

    readonly property string curatedGlyph: GlyphModel.glyphFor(
        root.itemRecord.desktopId, root.itemRecord.appId, root.itemRecord.name)
    readonly property bool useImage: !root.useCuratedGlyphs && !!root.itemRecord.iconSource

    implicitWidth: glyphSize
    implicitHeight: glyphSize
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

    Text {
        anchors.fill: parent
        visible: !root.useImage
        text: root.curatedGlyph || DockModel.fallbackGlyph(
            root.itemRecord.shortLabel, root.itemRecord.desktopId)
        color: root.tint
        font.family: Style.font.family
        font.pixelSize: root.glyphSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
