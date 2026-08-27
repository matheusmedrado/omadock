.pragma library

// Application to glyph-key resolution. The keys name entries in PixelGlyphs, so
// the artwork lives with the artwork and this file stays a lookup table.
//
// Resolution order is exact desktop id, then exact window app id, then a keyword
// scan over both plus the display name, then a generic window glyph. Keyword
// matching is what lets `org.gnome.Nautilus`, `nautilus`, and a window that only
// reports `Files` all land on the same folder glyph.

var DEFAULT_GLYPH = "window"

var EXACT = {
    "com.mitchellh.ghostty": "terminal",
    "org.gnome.nautilus": "folder",
    "org.gnome.settings": "settings",
    "app.zen_browser.zen": "browser",
    "zen": "browser",
    "chromium": "browser",
    "obsidian": "notes",
    "spotify": "music",
    "steam": "game",
    "code": "code",
    "org.gnome.texteditor": "notes"
}

var KEYWORDS = [
    { glyph: "terminal", terms: ["ghostty", "alacritty", "kitty", "wezterm", "foot",
        "konsole", "terminal", "termite", "urxvt", "tmux"] },
    { glyph: "browser", terms: ["firefox", "zen", "librewolf", "floorp", "waterfox",
        "chromium", "chrome", "brave", "vivaldi", "edge", "opera"] },
    { glyph: "folder", terms: ["nautilus", "thunar", "dolphin", "nemo", "caja", "pcmanfm",
        "files", "ranger", "yazi", "filemanager"] },
    { glyph: "code", terms: ["code", "vscodium", "zed", "neovim", "nvim", "helix",
        "emacs", "sublime", "jetbrains", "intellij", "pycharm", "goland", "webstorm",
        "cursor", "editor"] },
    { glyph: "music", terms: ["spotify", "rhythmbox", "audacious", "clementine",
        "tidal", "music", "mpd", "ncmpcpp"] },
    { glyph: "video", terms: ["mpv", "vlc", "celluloid", "obs", "video", "player"] },
    { glyph: "chat", terms: ["discord", "slack", "signal", "telegram", "element",
        "whatsapp", "matrix", "chat", "messenger"] },
    { glyph: "notes", terms: ["obsidian", "notion", "logseq", "joplin", "zotero",
        "notes", "note", "libreoffice", "onlyoffice", "writer", "impress",
        "office", "document"] },
    { glyph: "game", terms: ["steam", "lutris", "heroic", "bottles", "retroarch", "game"] },
    { glyph: "image", terms: ["gimp", "inkscape", "krita", "blender", "darktable",
        "photo", "image", "viewer", "loupe"] },
    { glyph: "mail", terms: ["thunderbird", "geary", "evolution", "mailspring", "mail"] },
    { glyph: "container", terms: ["docker", "podman", "container", "kubernetes"] },
    { glyph: "settings", terms: ["settings", "preferences", "control", "tweaks", "config"] },
    { glyph: "clipboard", terms: ["clipboard", "clipse", "copyq"] },
    { glyph: "shell", terms: ["hyprland", "omarchy", "compositor"] }
]

function normalize(value) {
    var text = String(value || "").trim().toLowerCase()
    return text.slice(-8) === ".desktop" ? text.slice(0, -8) : text
}

function exactGlyph(value) {
    var key = normalize(value)
    if (!key) return ""
    for (var candidate in EXACT) {
        if (normalize(candidate) === key) return EXACT[candidate]
    }
    return ""
}

function keywordGlyph(haystack) {
    if (!haystack) return ""
    for (var index = 0; index < KEYWORDS.length; index += 1) {
        var entry = KEYWORDS[index]
        for (var termIndex = 0; termIndex < entry.terms.length; termIndex += 1) {
            if (haystack.indexOf(entry.terms[termIndex]) >= 0) return entry.glyph
        }
    }
    return ""
}

function glyphFor(desktopId, appId, name) {
    var direct = exactGlyph(desktopId) || exactGlyph(appId)
    if (direct) return direct

    var haystack = [normalize(desktopId), normalize(appId), normalize(name)]
        .filter(function(part) { return part !== "" })
        .join(" ")
    return keywordGlyph(haystack) || DEFAULT_GLYPH
}

// Short command-style label. Terminal commands are lowercase, and the trailing
// vendor prefix in a reverse-DNS desktop id is noise next to a glyph, so only
// the final segment survives.
function commandLabel(name, desktopId, appId) {
    var source = String(name || "").trim()
    if (!source) source = String(desktopId || appId || "")

    var normalized = normalize(source)
    var dot = normalized.lastIndexOf(".")
    if (dot >= 0 && dot < normalized.length - 1 && normalized.indexOf(" ") < 0) {
        normalized = normalized.slice(dot + 1)
    }

    normalized = normalized.replace(/[\s_]+/g, "-").replace(/[^a-z0-9.+-]/g, "")
    if (!normalized) return "app"
    return normalized.slice(0, 14)
}
