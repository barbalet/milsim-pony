# Cycle 99 Smoke Test - Automated Capture Pipeline

Verify that the Canberra demo now behaves as a cycle `99` automated capture-pipeline pass: the app advertises the new cycle, the review capture command can batch title/live/map/scope/pause screenshots, and optional baseline comparison produces per-frame diff artifacts.

## Tool Validation

From the repository root, run:

```sh
Tools/capture_review.sh --validate-only
```

Confirm the command reports that capture tooling is valid and does not launch the app.

## Batch Capture

Run:

```sh
Tools/capture_review.sh
```

Confirm the command builds or reuses the Debug app, launches `MilsimPonyGame`, and writes an artifact directory under `artifacts/captures/`.

The output directory must contain:

- `capture_manifest.md`
- `01_title_shell.png`
- `02_live_route_start.png`
- `03_overhead_map.png`
- `04_scope_view.png`
- `05_pause_shell.png`

## Baseline Diff

Run a second capture against the first capture directory:

```sh
Tools/capture_review.sh --baseline artifacts/captures/<first-capture-directory>
```

Confirm the second output directory contains:

- `diff_manifest.md`
- `diffs/01_title_shell_diff.png`
- `diffs/02_live_route_start_diff.png`
- `diffs/03_overhead_map_diff.png`
- `diffs/04_scope_view_diff.png`
- `diffs/05_pause_shell_diff.png`

## App Identity

Launch the build and confirm:

- The briefing shell identifies `Canberra Automated Capture Pipeline`.
- The HUD title reads `Cycle 99 Automated Capture Pipeline`.
- The release display reports `v0.99.0 (99)`.
- The planning notes mention the scripted screenshot export and baseline diff workflow.

## Regression Checks

- Confirm the map, scope, pause shell, restore lines, route-selection lines, audio lines, and lighting plan still render.
- Confirm `Tools/package_release.sh --validate-only` passes with the Cycle 99 smoke test included in release docs.
