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

    // Orca ships as stably-orca with Categories=Development;IDE;TextEditor;
    // Nothing in the id or the name says "editor", so without categories it fell
    // back to the generic window glyph.
    function test_desktopCategoriesResolveApplicationsTheNameDoesNotDescribe() {
        compare(GlyphModel.glyphFor("stably-orca", "orca", "Orca",
                                    "Development;IDE;TextEditor;"), "code")
        compare(GlyphModel.glyphFor("stably-orca", "orca", "Orca", ""),
                GlyphModel.DEFAULT_GLYPH)
    }

    // A desktop entry lists several categories; the specific one has to win over
    // the broad one sitting beside it.
    function test_specificCategoryBeatsTheBroadOneBesideIt() {
        compare(GlyphModel.glyphFor("", "", "", "System;TerminalEmulator;"), "terminal")
        compare(GlyphModel.glyphFor("", "", "", "Network;WebBrowser;"), "browser")
        compare(GlyphModel.glyphFor("", "", "", "Utility;Settings;"), "settings")
        compare(GlyphModel.glyphFor("", "", "", "Graphics;2DGraphics;RasterGraphics;"), "image")
        compare(GlyphModel.glyphFor("", "", "", "Audio;Music;Player;AudioVideo;"), "music")
    }

    // A name the keyword scan recognises must not be overridden by a category.
    function test_nameStillWinsOverCategories() {
        compare(GlyphModel.glyphFor("", "ghostty", "Ghostty", "System;TerminalEmulator;"),
                "terminal")
        compare(GlyphModel.glyphFor("", "spotify", "Spotify", "Network;"), "music")
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
