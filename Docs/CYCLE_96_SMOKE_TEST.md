# Cycle 96 Smoke Test - Packaging Automation

Verify that the Canberra demo now behaves as a cycle `96` packaging-automation pass: the app remains on the current live route while release packaging has an explicit version policy, manifest validation, archive naming rule, and repeatable smoke command.

## Validation Command

From the repository root, run:

```bash
Tools/package_release.sh --validate-only
```

- Confirm the command reports `Release inputs validated`.
- Confirm the version policy is `0.96.0` with build `96`.
- Confirm the world manifest, coordinate-system file, scene file, and all sector files lint successfully.
- Confirm the release docs include `README.md`, `Docs/CYCLE_96_SMOKE_TEST.md`, and `Docs/DEVELOPMENT_BACKLOG.md`.

## Package Command

From the repository root, run:

```bash
Tools/package_release.sh
```

- Confirm a timestamped directory is created under `artifacts/release/`.
- Confirm the directory name follows `MilsimPonyGame-v0.96.0-b96-cycle96-<utc>`.
- Confirm the package contains `MilsimPonyGame.app`, `build_manifest.txt`, and `ReleaseDocs/`.
- Confirm a sibling zip file is produced for the same package directory.

## Manifest Review

- Confirm `build_manifest.txt` records product, version, build, bundle identifier, package time, git commit, git tree state, release cycle, version policy, archive pattern, world manifest, and included docs.
- Confirm package smoke validation fails if the app, manifest, or zip is missing.

## In-App Readout

- Launch the build and confirm the briefing shell identifies `Canberra Packaging Automation`.
- Confirm the mission overlay reports `Packaging:` with the app release display name, packaging status, cycle build/version policy, archive pattern, manifest checks, and smoke command.
- Confirm the overhead-map footer includes `Packaging:` after the LOD/reflection lines.

## Regression

- Confirm the route, map, `Scope Calibration:`, `CSM Profile:`, and `LOD Reflection:` readouts are still present.
- Confirm the app still loads the bundled Canberra world manifest rather than falling back to the procedural error scene.
