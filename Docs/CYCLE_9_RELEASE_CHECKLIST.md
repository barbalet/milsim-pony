# Cycle 9 Release Checklist

## Build Identity

- Confirm `MARKETING_VERSION` is `0.9.0`.
- Confirm `CURRENT_PROJECT_VERSION` is `9`.
- Confirm the app shell reports `v0.9.0 (9)` and `com.milsimpony.game`.

## Package Output

- Run `Tools/package_release.sh`.
- Confirm a fresh timestamped package appears under `artifacts/release/`.
- Confirm the package contains `MilsimPonyGame.app`, `build_manifest.txt`, and `ReleaseDocs/`.
- Confirm the sibling zip file exists and expands correctly.

## Bundled Content

- Launch the packaged app from the artifact directory.
- Confirm the shell reports `Content: bundled`.
- Confirm the asset, world-data, and manifest paths point into the packaged app resources rather than the workspace copy.

## Demo Regression

- Confirm the title shell loads instead of dropping directly into a run.
- Confirm pause, settings, retry, restart, return-to-briefing, and completion shells all still work.
- Confirm the route remains playable from State Circle South Verge to Extraction Canopy.
- Confirm observer failure and checkpoint retry still behave as expected.

## Docs And Sign-Off

- Confirm `Docs/CYCLE_9_SMOKE_TEST.md` matches the packaged build behavior.
- Confirm `Docs/CYCLE_9_RELEASE_NOTES.md` matches the shipped feature set.
- Confirm `Docs/CYCLE_9_RELEASE_CHECKLIST.md` is included inside `ReleaseDocs/`.
- Record final reviewer sign-off, package path, and distribution destination before sharing the zip.
