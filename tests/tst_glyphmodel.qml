import QtTest
import "../models/GlyphModel.js" as GlyphModel

TestCase {
    name: "GlyphModel"

    function test_exactIdsWinOverKeywords() {
        compare(GlyphModel.glyphFor("com.mitchellh.ghostty", "", ""),
                GlyphModel.glyphFor("", "alacritty", ""))
        verify(GlyphModel.glyphFor("org.gnome.Nautilus", "", "") !== GlyphModel.DEFAULT_GLYPH)
    }

    function test_appIdAndNameBothFeedKeywordMatching() {
        var browser = GlyphModel.glyphFor("", "firefox", "")
        compare(GlyphModel.glyphFor("", "", "Firefox Web Browser"), browser)
        compare(GlyphModel.glyphFor("org.mozilla.firefox", "", ""), browser)
    }

    function test_unknownApplicationsFallBackToTheWindowGlyph() {
        compare(GlyphModel.glyphFor("com.example.Unmatched", "unmatched", "Unmatched"),
                GlyphModel.DEFAULT_GLYPH)
        compare(GlyphModel.glyphFor("", "", ""), GlyphModel.DEFAULT_GLYPH)
    }

    function test_commandLabelReadsLikeAShellCommand() {
        compare(GlyphModel.commandLabel("Ghostty", "com.mitchellh.ghostty", ""), "ghostty")
        compare(GlyphModel.commandLabel("", "org.gnome.Nautilus", ""), "nautilus")
        compare(GlyphModel.commandLabel("Zen Browser", "zen", ""), "zen-browser")
        compare(GlyphModel.commandLabel("", "", ""), "app")
    }

    function test_commandLabelIsBounded() {
        verify(GlyphModel.commandLabel("A Very Long Application Name Indeed", "", "").length <= 14)
    }
}
