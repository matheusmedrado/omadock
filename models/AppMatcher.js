.pragma library

function normalizeId(value) {
    var id = String(value || "").toLowerCase()
    return id.endsWith(".desktop") ? id.slice(0, -8) : id
}
