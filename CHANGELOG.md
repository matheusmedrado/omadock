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
- A bar widget carrying the dock's dot-matrix glyph. Clicking it opens a
  preferences panel for hiding, layout, glyphs, and pointer actions; middle
  clicking toggles Smart Hide against never hiding. The panel writes through the
  same ConfigService the dock uses, so a change made there takes the same
  validation and atomic write as one typed into `config.json`, and the running
  dock applies it from its own file watcher without a restart. Pinned
  applications are still managed on the dock itself.
- `behavior.reserveSpace` now applies to every hide mode, not only `never`. A
  revealed dock takes an exclusive zone so windows move up rather than being
  covered, and gives it back once the dock has finished hiding.
- IPC on the `omadock` target: `reveal`, `conceal`, `toggle`, `revealOn`,
  `toggleOn`, and `status`, so the dock can be bound to a key. The bare forms act
  on the focused monitor; IPC requires every declared argument, so naming a
  monitor is a separate call rather than an optional one. The preferences panel
  moved to `omadock-settings` to leave the short target to the dock.
- `scripts/check` now validates every declared entry point rather than only the
  overlay.

### Changed

- Redesigned the dock as a terminal command strip: one bordered surface with a
  prompt, and a monochrome glyph beside a lowercase command-style label per
  application, replacing the row of bordered icon tiles.
- Application state is a brightness ladder with the application you are on at the
  top: focused is fully lit, running sits below it, and a pinned application that
  is not running is dimmest. Hovering lifts an entry one step, so a running window
  you are not focused on brightens too, not just an unopened one. The ladder is
  built from the theme's text colour rather than its accent, because an accent is
  frequently the darker of the two (Omarchy's default ships `#798186` against
  `#cacccc`) and colouring the focused entry with it put the one you were on below
  its neighbours. Accent now appears only on the marker under the focused entry.
- Nothing moves, resizes, or gains a background between states; the three-dot
  marker keeps its length and only changes colour.
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
  the strip. `appearance.showDither` and `appearance.ditherCell` control it.
- The strip is taller and roomier: a 28px glyph in a 40px row, up from 16 and 28.
- The surface is opaque by default. At the previous 0.94 the window behind
  showed through clearly enough to read.
- `behavior.clickAction`, `middleClickAction`, and `wheelAction` are read at last.
  They were validated but never consulted, so the pointer bindings were fixed in
  code. Each now accepts a real set of values, including `none` to unbind.

### Fixed

- Reserving space under Smart Hide would have deadlocked the dock open. Revealing
  pushes tiled windows clear, which erases the overlap that justified hiding, so
  the dock would reveal once and never hide again. Compensating the geometry by
  the live zone only moved the problem: the zone flips before the compositor has
  reflowed, and the stale reading bounced the dock straight back open, which was
  observed as a continuous reveal/hide cycle. With space reserved the conflict
  test now asks whether a tiled window is present at all rather than where it
  currently sits, which is the one form of the question that does not depend on
  the dock's own state.

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
