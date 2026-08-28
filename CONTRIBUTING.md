# Contributing to OmaDock

Thanks for taking an interest. OmaDock is a Quickshell plugin for Omarchy
Quattro, so almost everything here is QML plus a few plain-JavaScript model
files, and the whole thing runs inside the shell you are already using.

## Working on it

Point an Omarchy install at your checkout instead of a cloned copy:

```bash
ln -s "$PWD" ~/.config/omarchy/plugins/io.github.matheusmedrado.omadock
omarchy-shell shell rescanPlugins
omarchy plugin enable io.github.matheusmedrado.omadock
```

**Editing a file is not enough to see the change.** The shell's plugin
hot-reload does not pick up edits to a loaded plugin — the old code stays in
memory, which is a good way to spend an hour debugging a line number that no
longer exists. Restart the shell after every change:

```bash
omarchy-restart-shell
```

## Checks

Everything below runs in CI as the `static` check, except the pieces that need a
real Omarchy install:

```bash
./scripts/check      # manifest contract, entry points, changelog, QML tests
./scripts/smoke-test # omarchy plugin validate + qmllint; skipped off Omarchy
git diff --check
```

`scripts/check` enforces a few things worth knowing before they surprise you:
the manifest version must match the newest CHANGELOG heading, every declared
entry point must exist, and the README must keep referencing the preview image
and the permanent plugin ID.

The QML test suite under `tests/` covers the model layer — matching,
configuration validation, geometry, the hide state machine, glyph resolution.
That layer is deliberately plain JavaScript with no Quickshell imports so it can
be tested without a compositor, and new logic belongs there rather than inside a
component wherever there is a choice.

## Pull requests

`main` is protected: it takes no direct pushes, no force pushes, and no merge
commits, and the `static` check has to be green. Work on a branch and open a
pull request.

- One concern per pull request.
- Commit subjects are lowercase, imperative, and prefixed the way the existing
  history is: `feat:`, `fix:`, `docs:`, `ci:`, `test:`, `refactor:`.
- Explain *why* in the commit body and in comments. The code in this repository
  leans on comments that record the reason a thing is done the awkward way,
  because most of the awkward ways here are load-bearing.
- Add or update a CHANGELOG entry under the unreleased heading for anything a
  user would notice.

Merges are squash or rebase, since `main` keeps a linear history.

## Releases

Installing clones the default branch and `omarchy plugin update` fast-forwards
to its tip, so **users track `main`, not tags**. A release does not gate the
download; it marks a point in the history and gives the changelog somewhere to
land. That also means anything merged to `main` reaches every user on their next
update, which is the reason CI is a merge requirement.

To cut one:

1. Bump `version` in `manifest.json`.
2. Give the CHANGELOG a `## [x.y.z] - YYYY-MM-DD` heading matching it. The two
   are checked against each other, so a mismatch fails CI rather than shipping.
3. Merge that through a pull request like anything else.
4. Tag the merge commit and publish the release:

   ```bash
   git tag -a vx.y.z -m "OmaDock x.y.z"
   git push origin vx.y.z
   gh release create vx.y.z --title "OmaDock x.y.z" --notes-file <notes>
   ```

Versioning is semantic with respect to configuration: a change that invalidates
an existing `config.json` is a major bump, a new setting or behaviour is a
minor, and a fix that leaves configuration alone is a patch.

## Reporting a bug

Include your Omarchy and Quickshell versions, whether the dock is on Smart Hide,
and the relevant lines from the shell log:

```bash
journalctl --user -u omarchy-shell -n 200 --no-pager | grep -i omadock
```
