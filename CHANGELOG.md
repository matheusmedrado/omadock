# Changelog

All notable changes to OmaDock are documented here.

## [Unreleased]

### Added

- Pressing a dock entry now dips its brightness for as long as the button is
  held. Press previously shared the focused rung of the brightness ladder, so
  clicking the application you were already on produced no feedback at all.

### Changed

- The running marker sits under the application glyph instead of under the
  middle of the entry. An entry is as wide as its label, so on a long one the
  rule drifted out from under the mark it belongs to and the strip lost its
  baseline.
- The running marker sits on the glyph's own matrix, one pitch below its last
  row, so the two are separated by the same gutter the matrix uses everywhere
  else. The margin was three pixels against a four-pixel pitch, which left the
  run's dots flush against the glyph with no gutter at all.
- The break between pinned and running-unpinned applications is a column of
  dots rather than a text pipe, and the drag insertion marker is a column of
  dots rather than a solid rounded bar. Both were the only marks in the strip
  not drawn on the matrix everything else shares.
- The prompt opening the strip is drawn at 75% accent. At full accent it was
  the most saturated mark on the strip and competed with the focused entry's
  marker, which is the only other accent there is.
- The dither texture is chunkier and its ramp shorter: `appearance.ditherCell`
  now defaults to `3`, with the coverage pulled back to match, because a bigger
  cell carries more weight at the same coverage. A two-pixel cell reads as
  noise rather than as the deliberate ordered dither it is meant to be. An
  existing `config.json` keeps whatever `ditherCell` it already sets -- the new
  default only reaches a fresh install.
- An urgent application colours its glyph and its marker rather than its label
  as well. Repainting the label dropped a red word into a row of readable ones,
  which is harder to read and no more noticeable.

### Fixed

- Settings changed in the bar widget's preferences panel apply again. Two
  faults in the configuration writer combined to freeze it for the life of the
  process, so a change moved its own control and then did nothing, for every
  setting, until the shell was restarted.

  The writer queued the serialised configuration, handed it to the file view,
  and only then cleared the queue -- but a save whose content matches what is
  already on disk completes synchronously, and its completion handler calls
  straight back into the writer. That re-entry found the same text still queued
  and wrote it again, recursing until the stack was exhausted. The queue is now
  taken before the write rather than after it.

  The storm of overlapping writes that caused also made the file view drop
  operations, and a dropped operation never reports back: neither completion nor
  failure is emitted. The busy flag it left behind is checked both before
  writing and before re-reading the file, so a single lost write stopped the
  service from saving anything or noticing any external edit. A write that goes
  unanswered is now treated as lost, and the queue is retried.

- A hover tooltip no longer overlaps the top edge of the dock. It was placed
  flush to the item it points at, and an item sits inside the surface's content
  padding, so the tooltip landed on the dock's own rounded corner.

## [0.1.1] - 2026-08-28

### Fixed

- The dock no longer rebuilds itself when a window only changes its title. A
  terminal running an agent CLI rewrites its own title on a spinner cadence,
  and Hyprland re-emits `activewindow` alongside `windowtitle` for the focused
  window, so the dock was refreshing about once a second for every such
  terminal. Each refresh republished the window records, which rebuilt the item
  strip, and because the strip's Repeater is backed by a plain list QML cannot
  diff, every dock item was destroyed and recreated -- losing the hover under
  the pointer, restarting the colour easing, blinking any open tooltip, and
  cancelling a drag in progress. Window titles are now neither listened for nor
  compared, the focused window is tracked by address rather than by the
  `activewindow` payload that carries its title, and the record and item lists
  are compared by value so a rebuild that lands on the same answer is not
  republished. A dock sitting next to an idle agent terminal now makes no IPC
  calls at all, where it previously made one a second.
- Smart Hide no longer flicks the dock open while a window refresh is still
  settling. An incomplete set of window records was published before the
  retry that exists to reject it, and a record without a workspace reads as no
  conflict, so the dock revealed and then hid again as soon as the real
  geometry arrived. Incomplete sets are now held back until the retries are
  spent. With `behavior.reserveSpace` enabled this also stops the exclusive
  zone toggling on each false reveal, which was reflowing and re-animating
  tiled windows.
- Moving or resizing a window no longer rebuilds the dock items. Item state is
  compared on the window fields the strip actually draws from, so geometry
  changing on every frame of a drag stays with Smart Hide, where it is used.

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
- Application glyphs fall back to the desktop entry's freedesktop `Categories`
  before the generic window glyph, so an application whose id and name say
  nothing about what it is still gets a meaningful one. Orca ships as
  `stably-orca` with `Development;IDE;TextEditor;` and now reads as an editor.
  Across a sample of 48 installed applications this took the generic fallback
  from 25 down to 1.
- Dragging a pinned application clear of the strip unpins it, closing the loop
  with dragging a running one in to pin it. Only vertical distance counts:
  dragging past either end is how an item is moved to the front or back, so
  treating that as "outside" would turn reordering to an edge into a removal. A
  threshold of three quarters of the row height keeps a wobbly reorder from
  discarding the pin, and the dragged slot fades out once releasing would remove
  it rather than move it.
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
  low-resolution character. The `usePixelGlyphs` setting now means what its name
  always said; set it to false for each application's own icon instead.
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

- A pinned application that is not installed could not be removed. Both routes
  out -- the context menu and dragging clear of the strip -- were gated on the
  desktop entry resolving, so a pin left behind by an uninstalled application, or
  shipped as a default the machine never had, stayed in the dock permanently.
  Unpinning now only requires the entry to be pinned; pinning still requires
  something launchable.
- The default pins were Ghostty, Zen, and Nautilus, of which only Nautilus is in
  `omarchy-base.packages`. A fresh install on a machine without the other two got
  pins it could neither launch nor remove. The default is now Nautilus alone.

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
