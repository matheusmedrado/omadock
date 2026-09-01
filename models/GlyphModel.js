.pragma library

// Application to glyph-key resolution. The keys name entries in PixelGlyphs, so
// the artwork lives with the artwork and this file stays a lookup table.
//
// Resolution order is exact desktop id, then exact window app id, then the host
// a web application opens, then a keyword scan over the ids plus the display
// name, then the desktop entry categories, then a generic glyph. Keyword
// matching is what lets `org.gnome.Nautilus`, `nautilus`, and a window that only
// reports `Files` all land on the same folder glyph.

var DEFAULT_GLYPH = "window"

// What an application known to be a web application falls back to. The generic
// window glyph says "something is running"; this at least says what kind of
// thing, which is the whole difference the strip can draw.
var WEBAPP_GLYPH = "webapp"

var EXACT = {
    "com.mitchellh.ghostty": "terminal",
    "org.gnome.nautilus": "folder",
    "io.github.lgse.strata": "folder",
    "org.gnome.settings": "settings",
    "app.zen_browser.zen": "browser",
    "zen": "browser",
    "chromium": "browser",
    "obsidian": "notes",
    "spotify": "music",
    "steam": "game",
    "org.gnome.texteditor": "notes"
}

// Applications that draw as their own monogram rather than as the category they
// belong to. The semantic glyphs answer "what kind of thing is this", which is
// the right question until several of one kind sit in the strip together: eight
// installed applications resolve to the code glyph and four to chat, and a row
// of identical marks is a row you have to read the labels off.
//
// Only a brand that reduces to a letterform or a simple geometric primitive is
// eligible, because that is all that survives a seven-dot grid -- see the note
// above the artwork in PixelGlyphs for what happened to the ones that do not.
// An application with no entry here keeps its semantic glyph, which is a better
// mark than a blurred logo.
//
// Matched on the exact id, never as a substring: "zed" inside another id or
// name is a coincidence, not Zed. Both the desktop id and the window app id are
// tried, so an application resolves the same whether it is pinned or running.
var VENDOR = {
    "dev.zed.zed": "zed",
    "zed": "zed",
    "code": "vscode",
    "code-oss": "vscode",
    "visual-studio-code": "vscode",
    "com.visualstudio.code": "vscode",
    "nvim": "neovim",
    "neovim": "neovim",
    "cursor": "cursor",
    "co.anysphere.cursor": "cursor",
    "slack": "slack",
    "com.slack.slack": "slack",
    "discord": "discord",
    "com.discordapp.discord": "discord"
}

// Hosts a web application opens, and what that makes it. Omarchy's
// `omarchy-webapp-install` writes an entry with no `Categories=` and a name like
// `X` or `HEY`, so the address is the only description of the application that
// exists -- see webAppHost below for why it is read before the fuzzy passes.
//
// Bare hosts, never full addresses: `scripts/check` rejects a URL anywhere in
// the plugin tree, and nothing here is ever fetched or opened. These are
// compared against a host this file parsed out of a desktop entry, so they are
// strings to match, not addresses to visit.
var WEB_HOSTS = [
    { glyph: "video", terms: ["youtube.com", "youtu.be", "vimeo.com", "twitch.tv",
        "netflix.com", "disneyplus.com", "primevideo.com"] },
    { glyph: "music", terms: ["music.youtube.com", "open.spotify.com", "spotify.com",
        "soundcloud.com", "tidal.com", "bandcamp.com", "music.apple.com"] },
    { glyph: "map", terms: ["maps.google.com", "openstreetmap.org", "waze.com",
        "citymapper.com"] },
    { glyph: "mail", terms: ["mail.google.com", "gmail.com", "hey.com", "outlook.com",
        "mail.proton.me", "fastmail.com", "mail.zoho.com", "roundcube.org"] },
    { glyph: "contacts", terms: ["contacts.google.com", "people.google.com"] },
    { glyph: "call", terms: ["zoom.us", "meet.google.com", "teams.microsoft.com",
        "whereby.com", "meet.jit.si"] },
    { glyph: "chat", terms: ["messages.google.com", "web.whatsapp.com", "whatsapp.com",
        "discord.com", "slack.com", "web.telegram.org", "telegram.org", "signal.org",
        "messenger.com", "x.com", "twitter.com", "bsky.app", "reddit.com",
        "mastodon.social", "app.element.io"] },
    { glyph: "spreadsheet", terms: ["sheets.google.com"] },
    { glyph: "presentation", terms: ["slides.google.com"] },
    { glyph: "notes", terms: ["docs.google.com", "keep.google.com", "notion.so",
        "obsidian.md", "linear.app", "basecamp.com", "37signals.com", "trello.com",
        "asana.com", "todoist.com", "roamresearch.com"] },
    { glyph: "image", terms: ["photos.google.com", "figma.com", "unsplash.com",
        "instagram.com", "pinterest.com", "excalidraw.com"] },
    { glyph: "code", terms: ["github.com", "gitlab.com", "codeberg.org", "codepen.io",
        "stackoverflow.com", "replit.com"] },
    { glyph: "disk", terms: ["drive.google.com", "dropbox.com", "nextcloud.com"] },
    { glyph: "monitor", terms: ["grafana.com", "datadoghq.com", "status.cloud.google.com"] }
]

var KEYWORDS = [
    { glyph: "terminal", terms: ["ghostty", "alacritty", "kitty", "wezterm", "foot",
        "konsole", "terminal", "termite", "urxvt", "tmux"] },
    { glyph: "browser", terms: ["firefox", "zen", "librewolf", "floorp", "waterfox",
        "chromium", "chrome", "brave", "vivaldi", "edge", "opera"] },
    { glyph: "folder", terms: ["nautilus", "thunar", "dolphin", "nemo", "caja", "pcmanfm",
        "strata", "files", "ranger", "yazi", "filemanager"] },
    { glyph: "code", terms: ["code", "vscodium", "zed", "neovim", "nvim", "helix",
        "emacs", "sublime", "jetbrains", "intellij", "pycharm", "goland", "webstorm",
        "cursor", "editor"] },
    { glyph: "music", terms: ["spotify", "rhythmbox", "audacious", "clementine",
        "tidal", "music", "mpd", "ncmpcpp"] },
    { glyph: "video", terms: ["mpv", "vlc", "celluloid", "obs", "video", "player"] },
    { glyph: "call", terms: ["zoom", "jitsi", "webex", "bluejeans"] },
    { glyph: "chat", terms: ["discord", "slack", "signal", "telegram", "element",
        "whatsapp", "matrix", "chat", "messenger"] },
    // The office suite ships one binary name per document type, and the suite
    // name is in every one of them. `libreoffice` sat in the notes entry, so
    // the spreadsheet, the presentation, and the drawing were all resolved as a
    // notepad before their categories were ever consulted. The specific
    // document types have to be matched ahead of the suite that contains them.
    { glyph: "spreadsheet", terms: ["spreadsheet", "gnumeric", "localc",
        "libreoffice-calc"] },
    { glyph: "presentation", terms: ["presentation", "impress", "powerpoint"] },
    { glyph: "image", terms: ["libreoffice-draw", "drawing", "draw.io"] },
    { glyph: "disk", terms: ["gparted", "baobab", "filelight", "diskusage", "disk",
        "snapper", "snapshot", "database", "dbeaver", "postgres", "sqlite",
        "libreoffice-base"] },
    { glyph: "notes", terms: ["obsidian", "notion", "logseq", "joplin", "zotero",
        "notes", "note", "libreoffice", "onlyoffice", "writer", "office", "document",
        "evince", "zathura", "okular", "mupdf", "foliate", "calibre", "xournal"] },
    { glyph: "game", terms: ["steam", "lutris", "heroic", "bottles", "retroarch", "game"] },
    { glyph: "image", terms: ["gimp", "inkscape", "krita", "blender", "darktable",
        "photo", "image", "viewer", "loupe", "pinta"] },
    { glyph: "mail", terms: ["thunderbird", "geary", "evolution", "mailspring", "mail"] },
    { glyph: "contacts", terms: ["contacts", "addressbook"] },
    { glyph: "calculator", terms: ["calculator", "qalculate", "galculator", "omacalc",
        "kcalc"] },
    // Not bare "top": it is a substring of "desktop", which is in the name of
    // half the settings panels on the system.
    { glyph: "monitor", terms: ["btop", "htop", "atop", "glances", "mission-center",
        "sysmon", "monitor"] },
    { glyph: "printer", terms: ["printer", "printing"] },
    // Not bare "ark": it is a substring of "dark", "mark", and "spark".
    { glyph: "archive", terms: ["file-roller", "xarchiver", "engrampa", "peazip",
        "archive", "unzip"] },
    { glyph: "download", terms: ["transmission", "qbittorrent", "deluge", "motrix",
        "jdownloader", "torrent", "download", "localsend", "warpinator"] },
    { glyph: "map", terms: ["maps", "openstreetmap", "organicmaps", "navigation"] },
    { glyph: "container", terms: ["docker", "podman", "container", "kubernetes",
        "virtualbox", "vmware", "qemu", "virt-manager", "distrobox", "incus"] },
    { glyph: "settings", terms: ["settings", "preferences", "control", "tweaks",
        "config", "fcitx", "ibus"] },
    { glyph: "clipboard", terms: ["clipboard", "clipse", "copyq"] },
    { glyph: "shell", terms: ["hyprland", "omarchy", "compositor"] }
]

// Freedesktop `Categories=` from the desktop entry, consulted when neither the
// id nor the name says anything. This is what stops most applications falling
// back to the generic window glyph: an entry declaring
// `Development;IDE;TextEditor;` is an editor whether or not its name happens to
// contain a word this file knows.
//
// Scanned in order, so the specific category wins over the broad one it sits
// next to -- `System;TerminalEmulator;` is a terminal, not a settings panel, and
// `Network;WebBrowser;` is a browser rather than a generic network tool.
//
// There is deliberately no catch-all at the end. `System;`, `Utility;`, and
// `Network;` used to resolve to the settings gear and the browser ring, which
// meant a disk utility, a Java console, and a torrent client all claimed to be
// preferences panels. A confident wrong glyph is worse than the window glyph:
// the window glyph is read as "unrecognised", and acted on accordingly, while a
// gear is read as an answer. Anything these terms do not describe falls through
// to `window` on purpose.
var CATEGORY_GLYPHS = [
    { glyph: "terminal", terms: ["terminalemulator"] },
    { glyph: "browser", terms: ["webbrowser"] },
    { glyph: "folder", terms: ["filemanager", "filetools"] },
    { glyph: "code", terms: ["development", "ide", "texteditor", "building", "debugger",
        "guidesigner", "profiling", "revisioncontrol"] },
    { glyph: "chat", terms: ["instantmessaging", "chat", "ircclient"] },
    { glyph: "call", terms: ["videoconference", "telephony"] },
    { glyph: "contacts", terms: ["contactmanagement"] },
    { glyph: "mail", terms: ["email"] },
    { glyph: "music", terms: ["audio", "music", "midi", "mixer", "sequencer", "tuner"] },
    // `AudioVideo` is the primary freedesktop media category and the only one a
    // minimal media entry declares. It was absent from this table, so an entry
    // carrying nothing else fell all the way through to the window glyph.
    { glyph: "video", terms: ["video", "player", "recorder", "tv", "audiovideoediting",
        "audiovideo"] },
    // Office subtypes ahead of `Office` itself, for the same reason the keyword
    // table splits them: a spreadsheet and a presentation are not a notepad.
    // FlowChart is what separates the suite's drawing program from its document
    // viewer, since both also declare Graphics and VectorGraphics.
    { glyph: "spreadsheet", terms: ["spreadsheet"] },
    { glyph: "presentation", terms: ["presentation"] },
    { glyph: "image", terms: ["flowchart"] },
    { glyph: "calculator", terms: ["calculator"] },
    { glyph: "disk", terms: ["database", "filesystem"] },
    { glyph: "archive", terms: ["archiving", "compression"] },
    { glyph: "download", terms: ["filetransfer", "p2p"] },
    { glyph: "printer", terms: ["printing"] },
    { glyph: "monitor", terms: ["monitor"] },
    { glyph: "notes", terms: ["office", "wordprocessor", "documentation", "publishing",
        "calendar", "projectmanagement", "dictionary", "literature", "education",
        "science"] },
    { glyph: "image", terms: ["graphics", "photography", "rastergraphics",
        "vectorgraphics", "2dgraphics", "3dgraphics", "scanning", "ocr", "viewer"] },
    { glyph: "game", terms: ["game"] },
    { glyph: "container", terms: ["emulator", "virtualization"] },
    // Ahead of settings: `Settings;DesktopSettings;` is the compositor's own
    // configuration, not an application preferences panel.
    { glyph: "shell", terms: ["desktopsettings", "windowmanager", "screensaver"] },
    { glyph: "settings", terms: ["settings", "preferences", "hardwaresettings",
        "packagemanager", "security", "accessibility"] },
    { glyph: "browser", terms: ["webdevelopment"] }
]

// Whole tokens, not substrings. Categories are semicolon-delimited, and a
// substring scan matches across them: "AudioVideo" contains "ide", so a music
// player resolved to the code glyph.
function categoryGlyph(categories) {
    var present = {}
    var tokens = normalize(categories).split(";")
    for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex += 1) {
        var token = tokens[tokenIndex].replace(/[^a-z0-9]/g, "")
        if (token) present[token] = true
    }

    for (var index = 0; index < CATEGORY_GLYPHS.length; index += 1) {
        var entry = CATEGORY_GLYPHS[index]
        for (var termIndex = 0; termIndex < entry.terms.length; termIndex += 1) {
            if (present[entry.terms[termIndex]]) return entry.glyph
        }
    }
    return ""
}

function normalize(value) {
    var text = String(value || "").trim().toLowerCase()
    return text.slice(-8) === ".desktop" ? text.slice(0, -8) : text
}

// A vendor monogram outranks the semantic override, which is the whole point of
// having one: `code` used to resolve to the generic bracket glyph it shared with
// seven other applications.
function exactGlyph(value) {
    var key = normalize(value)
    if (!key) return ""
    for (var vendorId in VENDOR) {
        if (normalize(vendorId) === key) return VENDOR[vendorId]
    }
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

// Whether the `Exec=` line launches a site rather than a program. Omarchy writes
// two forms and both have to be recognised: `omarchy-launch-webapp <address>`
// for an ordinary web application, and `omarchy-webapp-handler-<service> %u`
// for one that also registers a scheme handler, which names the service in the
// script and carries no address at all. `--app=` covers the web applications a
// user made by hand with a Chromium-derived browser.
//
// Matching `--app=` with its equals sign is deliberate: `--app-id=`, which a
// terminal entry uses to place its window, is not a web application. Reading it
// as one would have given the "Disk Usage" terminal utility a globe.
var WEBAPP_LAUNCHER = "omarchy-launch-webapp"
var WEBAPP_HANDLER = "omarchy-webapp-handler-"
var WEBAPP_FLAG = "--app="

function isWebApp(exec) {
    var text = String(exec || "").toLowerCase()
    return text.indexOf(WEBAPP_LAUNCHER) >= 0
        || text.indexOf(WEBAPP_HANDLER) >= 0
        || text.indexOf(WEBAPP_FLAG) >= 0
}

// The service name out of the handler form, e.g. `hey` from
// `omarchy-webapp-handler-hey %u`.
function webAppSlug(exec) {
    var text = String(exec || "").toLowerCase()
    var mark = text.indexOf(WEBAPP_HANDLER)
    if (mark < 0) return ""

    var rest = text.slice(mark + WEBAPP_HANDLER.length)
    var slug = rest.split(/\s+/)[0]
    return slug.replace(/[^a-z0-9-]/g, "")
}

// A handler slug against the host table, so the two Exec forms resolve from one
// list rather than two that can drift apart. Only a bare registrable domain
// contributes a slug: `hey.com` offers `hey`, but `web.whatsapp.com` must not
// offer `web`, which would be a slug generic enough to match the wrong service.
function webSlugGlyph(slug) {
    if (!slug) return ""

    for (var index = 0; index < WEB_HOSTS.length; index += 1) {
        var entry = WEB_HOSTS[index]
        for (var termIndex = 0; termIndex < entry.terms.length; termIndex += 1) {
            var labels = entry.terms[termIndex].split(".")
            if (labels.length === 2 && labels[0] === slug) return entry.glyph
        }
    }
    return ""
}

// The host out of a web application's `Exec=` line, lowercased and without a
// leading `www.`. Split on "//" rather than matching a scheme, so no address
// pattern has to be written into a file `scripts/check` scans for one.
function webAppHost(exec) {
    if (!isWebApp(exec)) return ""

    var parts = String(exec).toLowerCase().split(/\s+/)
    for (var index = 0; index < parts.length; index += 1) {
        var token = parts[index]
        var mark = token.indexOf("//")
        if (mark < 0) continue

        var host = token.slice(mark + 2).split("/")[0].split("?")[0].split("#")[0]
        // Strip credentials and a port, neither of which identifies the service.
        var at = host.lastIndexOf("@")
        if (at >= 0) host = host.slice(at + 1)
        host = host.split(":")[0]
        if (host.slice(0, 4) === "www.") host = host.slice(4)
        if (host) return host
    }
    return ""
}

// Exact host before any suffix match. `music.youtube.com` and `youtube.com` are
// different applications that a user may well pin side by side, and a scan that
// accepted the suffix first would hand the music one the video glyph.
function webHostGlyph(host) {
    if (!host) return ""

    for (var index = 0; index < WEB_HOSTS.length; index += 1) {
        var entry = WEB_HOSTS[index]
        for (var termIndex = 0; termIndex < entry.terms.length; termIndex += 1) {
            if (host === entry.terms[termIndex]) return entry.glyph
        }
    }

    // A subdomain the table does not name still belongs to the service it sits
    // under, so `m.youtube.com` and `www2.github.com` resolve rather than
    // falling back. Anchored on a dot so `notyoutube.com` does not match.
    for (var suffixIndex = 0; suffixIndex < WEB_HOSTS.length; suffixIndex += 1) {
        var suffixEntry = WEB_HOSTS[suffixIndex]
        for (var suffixTerm = 0; suffixTerm < suffixEntry.terms.length; suffixTerm += 1) {
            var term = suffixEntry.terms[suffixTerm]
            if (host.length > term.length
                    && host.slice(-(term.length + 1)) === "." + term) {
                return suffixEntry.glyph
            }
        }
    }
    return ""
}

function glyphFor(desktopId, appId, name, categories, exec) {
    var direct = exactGlyph(desktopId) || exactGlyph(appId)
    if (direct) return direct

    // A web application carries its identity in the address it opens and nowhere
    // else: `omarchy-webapp-install` writes no `Categories=` at all, and a name
    // like `X` or `HEY` is nothing a keyword scan can use -- a single letter as
    // a search term would match most of the strip. So the host is read ahead of
    // the fuzzy passes, not after them.
    var hosted = webHostGlyph(webAppHost(exec)) || webSlugGlyph(webAppSlug(exec))
    if (hosted) return hosted

    var haystack = [normalize(desktopId), normalize(appId), normalize(name)]
        .filter(function(part) { return part !== "" })
        .join(" ")
    var resolved = keywordGlyph(haystack) || categoryGlyph(categories)
    if (resolved) return resolved

    return isWebApp(exec) ? WEBAPP_GLYPH : DEFAULT_GLYPH
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
