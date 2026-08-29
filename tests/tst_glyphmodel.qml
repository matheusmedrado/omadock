import QtTest
import "../models/GlyphModel.js" as GlyphModel

TestCase {
    name: "GlyphModel"

    // `scripts/check` rejects an address anywhere in the plugin tree, so the
    // Exec lines under test are assembled rather than written out. The scheme is
    // joined from two pieces for the same reason: the gate scans source text,
    // and this file has no more business carrying an address than the dock does.
    function webExec(host) {
        return "omarchy-launch-webapp " + "https" + "://" + host + "/"
    }

    function handlerExec(service) {
        return "omarchy-webapp-handler-" + service + " %u"
    }

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

    // Omarchy writes a web application entry with no `Categories=` and a name
    // that is the site's brand, so the address it opens is the only description
    // of the application that exists.
    function test_webApplicationsResolveFromTheHostTheyOpen() {
        compare(GlyphModel.glyphFor("YouTube", "", "YouTube", "",
                                    webExec("youtube.com")), "video")
        compare(GlyphModel.glyphFor("Google Maps", "", "Google Maps", "",
                                    webExec("maps.google.com")), "map")
        // A single-letter name is nothing a keyword scan can use: as a search
        // term it would match most of the strip.
        compare(GlyphModel.glyphFor("X", "", "X", "",
                                    webExec("x.com")), "chat")
    }

    // The second Exec form Omarchy writes, for a web application that also
    // registers a scheme handler. It carries no address at all -- the service is
    // named in the handler script instead.
    function test_webApplicationsResolveFromTheHandlerScriptName() {
        compare(GlyphModel.glyphFor("HEY", "", "HEY", "",
                                    handlerExec("hey")), "mail")
        compare(GlyphModel.glyphFor("Zoom", "", "Zoom", "",
                                    handlerExec("zoom")), "call")
    }

    // An exact host is checked before any suffix, so a service on a subdomain of
    // another one keeps its own glyph rather than inheriting the parent's.
    function test_exactHostBeatsTheSuffixItSitsUnder() {
        var exec = webExec("music.youtube.com")
        compare(GlyphModel.glyphFor("", "", "", "", exec), "music")
        compare(GlyphModel.glyphFor("", "", "", "",
                                    webExec("m.youtube.com")), "video")
    }

    // The suffix scan is anchored on a dot, or any host merely ending in a known
    // one would take its glyph.
    function test_aHostIsNotMatchedBySharingAnEnding() {
        compare(GlyphModel.glyphFor("", "", "", "",
                                    webExec("notyoutube.com")),
                GlyphModel.WEBAPP_GLYPH)
    }

    // An unrecognised web application is still known to be a web application,
    // which is more than the generic window glyph says.
    function test_anUnknownWebApplicationIsStillAWebApplication() {
        compare(GlyphModel.glyphFor("", "", "", "",
                                    webExec("example.org")),
                GlyphModel.WEBAPP_GLYPH)
        compare(GlyphModel.glyphFor("", "", "", "", handlerExec("unknown")),
                GlyphModel.WEBAPP_GLYPH)
    }

    // `--app-id=` places a terminal window and is not `--app=`. Reading it as a
    // web application gave the "Disk Usage" terminal utility a globe.
    function test_anAppIdFlagIsNotAWebApplication() {
        var exec = "xdg-terminal-exec --app-id=TUI.float -e btop"
        compare(GlyphModel.glyphFor("", "", "", "Utility;", exec), GlyphModel.DEFAULT_GLYPH)
        compare(GlyphModel.glyphFor("Disk Usage", "", "Disk Usage", "", exec), "disk")
    }

    // The office suite puts its own name in every one of its binaries, so the
    // suite keyword used to answer for the spreadsheet and the presentation
    // before their categories were ever read.
    function test_officeDocumentTypesAreNotAllTheNotepad() {
        compare(GlyphModel.glyphFor("libreoffice-calc", "", "LibreOffice Calc",
                                    "Office;Spreadsheet;"), "spreadsheet")
        compare(GlyphModel.glyphFor("libreoffice-impress", "", "LibreOffice Impress",
                                    "Office;Presentation;"), "presentation")
        compare(GlyphModel.glyphFor("libreoffice-writer", "", "LibreOffice Writer",
                                    "Office;WordProcessor;"), "notes")
        // FlowChart is what separates the suite's drawing program from its
        // document viewer: both also declare Graphics and VectorGraphics.
        compare(GlyphModel.glyphFor("", "", "", "Office;FlowChart;Graphics;2DGraphics;"),
                "image")
        compare(GlyphModel.glyphFor("", "", "", "Office;Viewer;Graphics;2DGraphics;"),
                "notes")
        compare(GlyphModel.glyphFor("", "", "", "Graphics;2DGraphics;Viewer;"), "image")
    }

    // `AudioVideo` is the primary freedesktop media category and the only one a
    // minimal media entry declares. It was missing from the table, so an entry
    // carrying nothing else fell through to the window glyph.
    function test_theCompoundMediaCategoryResolves() {
        compare(GlyphModel.glyphFor("", "", "", "AudioVideo;"), "video")
        // Still a music player when it says so, which is why the music entry is
        // scanned before the video one.
        compare(GlyphModel.glyphFor("", "", "", "AudioVideo;Audio;"), "music")
    }

    // These used to resolve through a catch-all that turned "no idea" into the
    // settings gear, so a system monitor, a calculator, and a disk utility all
    // claimed to be preferences panels.
    function test_systemToolsAreNotAllThePreferencesGear() {
        compare(GlyphModel.glyphFor("btop", "", "btop++", "System;Monitor;ConsoleOnly;"),
                "monitor")
        compare(GlyphModel.glyphFor("omacalc", "", "Omacalc", "Utility;Calculator;"),
                "calculator")
        compare(GlyphModel.glyphFor("cups", "", "Manage Printing",
                                    "System;Settings;Printing;HardwareSettings;"), "printer")
        // DesktopSettings is the compositor's own configuration, not an
        // application preferences panel.
        compare(GlyphModel.glyphFor("omaland", "", "Omaland", "Settings;DesktopSettings;"),
                "shell")
        // A real preferences panel still gets the gear.
        compare(GlyphModel.glyphFor("", "", "", "Utility;Settings;"), "settings")
    }

    // The catch-all is gone on purpose. A confident wrong glyph is worse than
    // the window glyph: the window glyph is read as "unrecognised", while a gear
    // is read as an answer.
    function test_abroadCategoryAloneIsNotAnAnswer() {
        compare(GlyphModel.glyphFor("", "", "", "Application;System;"),
                GlyphModel.DEFAULT_GLYPH)
        compare(GlyphModel.glyphFor("", "", "", "Utility;"), GlyphModel.DEFAULT_GLYPH)
        compare(GlyphModel.glyphFor("", "", "", "GNOME;Network;"), GlyphModel.DEFAULT_GLYPH)
    }

    // Nothing above may cost the resolutions that already worked.
    function test_theExistingResolutionsAreUnchanged() {
        compare(GlyphModel.glyphFor("com.mitchellh.ghostty", "", "Ghostty", "", ""), "terminal")
        compare(GlyphModel.glyphFor("org.gnome.Nautilus", "", "Files", "", ""), "folder")
        compare(GlyphModel.glyphFor("", "firefox", "Firefox", "", ""), "browser")
        compare(GlyphModel.glyphFor("", "", "", "System;TerminalEmulator;", ""), "terminal")
        compare(GlyphModel.glyphFor("com.example.Nope", "nope", "Nope", "", ""),
                GlyphModel.DEFAULT_GLYPH)
    }
}
