import QtQuick
import qs.Commons

Item {
    id: root

    property var itemRecord: ({})
    property int iconSize: 24
    property bool usePixelGlyphs: true

    width: iconSize
    height: iconSize

    Image {
        anchors.fill: parent
        visible: !!root.itemRecord.iconSource
        source: root.itemRecord.iconSource || ""
        fillMode: Image.PreserveAspectFit
        smooth: !root.usePixelGlyphs
        mipmap: !root.usePixelGlyphs
    }

    Text {
        anchors.fill: parent
        visible: !root.itemRecord.iconSource
        text: root.itemRecord.missing ? "?" : (root.itemRecord.shortLabel || "APP").slice(0, 2)
        color: Color.bar.text
        font.family: Style.font.family
        font.pixelSize: Math.max(Style.font.body, root.iconSize * 0.42)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
