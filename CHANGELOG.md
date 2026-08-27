# Changelog

All notable changes to OmaDock are documented here.

## [0.1.0] - 2026-08-27

### Added

- Initial Omarchy Quattro overlay plugin contract.
- Terminal-inspired dock architecture and configuration schema.
- Smart Hide with edge reveal, fullscreen suspension, and monitor-local state.
- Pinned and running application items with launch, focus, and cycling actions.
- Safe context-menu actions and drag reorder with persistent configuration.
- Omarchy theme-driven command-strip visuals with status markers and counts.

### Changed

- Redesigned the dock as a terminal command strip: one bordered surface with a
  prompt, monochrome Nerd Font glyphs tinted to the theme, and a lowercase
  command-style label per application, replacing the row of bordered icon tiles.
- Application state now reads as a marker rule — an accent rule under the focused
  application, a short dim rule under one that is merely running, and nothing
  under a pinned application that is not running.
- Scroll-to-cycle accumulates wheel deltas into notches, so one touchpad flick no
  longer cycles through every window at once, and scrolling back cycles backwards.
- Window lists sort by address so "next window" stays stable between rebuilds.
- Labels are shown by default and slot numbers hidden, matching the new layout.
- Application glyphs are drawn as a 7x7 dot matrix rather than font icons, so the
  artwork lives in the repository as editable bitmaps and shares the dock's
  low-resolution character. `assets/glyphs` and the `usePixelGlyphs` setting now
  mean what their names always said; set it to false for real application icons.
- The prompt and the marker rules sit on the same matrix as the glyphs, so the
  whole strip reads as one dot grid instead of mixing dots with vector strokes.
- Added an ordered-dither (Bayer) texture that gathers along the bottom edge of
  the strip, with hover and press drawn as a dithered wash rather than a flat
  translucent fill. `appearance.showDither` and `appearance.ditherCell` control
  it.
- The strip is taller and roomier: a 28px glyph in a 40px row, up from 16 and 28.
- The surface is opaque by default. At the previous 0.94 the window behind
  showed through clearly enough to read.
- `behavior.clickAction`, `middleClickAction`, and `wheelAction` are read at last.
  They were validated but never consulted, so the pointer bindings were fixed in
  code. Each now accepts a real set of values, including `none` to unbind.

### Fixed

- Smart Hide never hid the dock. Window records resolved through the
  `HyprlandToplevel` attached handle, which names the right window but carries no
  workspace, monitor, or IPC payload, so every record compared as "not on this
  workspace" and no window ever registered as a conflict. Records now resolve the
  populated entry from `Hyprland.toplevels` by address.
- Window geometry was always discarded. Hyprland reports `at` and `size` as
  QVariantList, which `Array.isArray` rejects, so every window fell back to the
  no-geometry path.
- The dock could settle in a visible state it should have left. The hide state
  machine only re-evaluated when an input changed, so a window that began
  overlapping while the dock was still revealing left it shown indefinitely.
- Revealing from the screen edge immediately hid again. The dock sits one edge
  margin above the sensor, so a stationary pointer was never over the dock and
  the hide delay expired under it.
- The focused-application marker never lit up, and cycling windows did nothing:
  `itemRecord.windows` crosses into the delegate as QVariantList and failed the
  same `Array.isArray` guard.
- Editing `config.json` could silently overwrite it with defaults. A watcher read
  of a file truncated mid-save was treated as an empty configuration.
- `config.json` is now seeded on first run instead of never being written.
- `DockIcon.qml` used `DockModel` without importing it, so the text fallback
  raised `ReferenceError` for every application without a resolvable icon.
- `config/defaults.json` had drifted from the defaults the dock actually uses; a
  test now pins the two together.
