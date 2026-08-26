.pragma library

function normalizeId(value) {
    var id = String(value || "").trim().toLowerCase()
    return id.slice(-8) === ".desktop" ? id.slice(0, -8) : id
}

function isArray(value) {
    return Array.isArray(value)
}

function entryId(entry) {
    if (!entry) return ""
    return String(entry.desktopId || entry.id || "").trim()
}

function startupClass(entry) {
    if (!entry) return ""
    return entry.startupWmClass || entry.startupClass || entry.startupWMClass || ""
}

function values(entry) {
    if (isArray(entry)) return entry
    return entry ? [entry] : []
}

function findById(entries, wanted) {
    var normalizedWanted = normalizeId(wanted)
    var list = values(entries)
    for (var index = 0; index < list.length; index += 1) {
        if (normalizeId(entryId(list[index])) === normalizedWanted) return list[index]
    }
    return null
}

function idMatchMethod(entry, appId) {
    var entryText = entryId(entry)
    var appText = String(appId || "").trim()
    var appWithoutSuffix = appText.toLowerCase().slice(-8) === ".desktop"
        ? appText.slice(0, -8)
        : appText
    if (entryText === appText || entryText === appWithoutSuffix) return "exact"
    if (entryText.toLowerCase() === appWithoutSuffix.toLowerCase()) return "case-insensitive"
    return "case-insensitive"
}

function findByStartupClass(entries, wanted) {
    var normalizedWanted = normalizeId(wanted)
    var list = values(entries)
    var matches = []

    for (var index = 0; index < list.length; index += 1) {
        var entry = list[index]
        var classes = values(startupClass(entry))
        for (var classIndex = 0; classIndex < classes.length; classIndex += 1) {
            if (normalizeId(classes[classIndex]) === normalizedWanted) {
                matches.push(entry)
                break
            }
        }
    }

    return matches.length === 1 ? matches[0] : null
}

function basename(value) {
    var normalized = normalizeId(value)
    var slash = normalized.lastIndexOf("/")
    if (slash >= 0) normalized = normalized.slice(slash + 1)

    var dot = normalized.lastIndexOf(".")
    if (dot >= 0) normalized = normalized.slice(dot + 1)
    return normalized
}

function findByBasename(entries, wanted) {
    var normalizedWanted = basename(wanted)
    if (normalizedWanted.length < 3) return null

    var list = values(entries)
    var matches = []
    for (var index = 0; index < list.length; index += 1) {
        if (basename(entryId(list[index])) === normalizedWanted) matches.push(list[index])
    }

    return matches.length === 1 ? matches[0] : null
}

function match(appId, entries, aliases, heuristicLookup) {
    var normalizedAppId = normalizeId(appId)
    if (!normalizedAppId) return null

    var aliasTarget = aliases && aliases[normalizedAppId]
    if (aliasTarget) {
        var aliasedEntry = findById(entries, aliasTarget)
        return aliasedEntry ? {
            entry: aliasedEntry,
            method: "alias"
        } : {
            entry: null,
            method: "alias-missing"
        }
    }

    var exactEntry = findById(entries, appId)
    if (exactEntry) {
        return {
            entry: exactEntry,
            method: idMatchMethod(exactEntry, appId)
        }
    }

    var startupEntry = findByStartupClass(entries, appId)
    if (startupEntry) {
        return {
            entry: startupEntry,
            method: "startup-wm-class"
        }
    }

    if (typeof heuristicLookup === "function") {
        var heuristicEntry = heuristicLookup(appId)
        if (heuristicEntry) {
            return {
                entry: heuristicEntry,
                method: "heuristic"
            }
        }
    }

    var basenameEntry = findByBasename(entries, appId)
    if (basenameEntry) {
        return {
            entry: basenameEntry,
            method: "basename"
        }
    }

    return null
}
