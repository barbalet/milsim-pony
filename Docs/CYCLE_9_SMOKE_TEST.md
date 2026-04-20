# Cycle 9 Smoke Test

## Goal

Verify that the Canberra slice now behaves as a cycle `9` release candidate: the app reports an explicit release version and build, packaged builds prefer their bundled content instead of falling back to the workspace copy, and a repeatable packaging command emits a reviewable zip with the app, notes, checklist, and smoke test.

## Release Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Release -derivedDataPath /tmp/MilsimPonyReleaseDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyReleaseDerived/Build/Products/Release/`.
- The built app Info.plist reports `CFBundleShortVersionString = 0.9.0` and `CFBundleVersion = 9`.

## Packaging Command

Run:

```bash
Tools/package_release.sh
```

Expected result:

- The script builds the Release configuration without requesting signing.
- A timestamped directory is created under `artifacts/release/`.
- The directory contains `MilsimPonyGame.app`, `build_manifest.txt`, and a `ReleaseDocs/` folder.
- A sibling zip file is produced for the same timestamped package directory.

## Packaged Contents

Expected result:

- `build_manifest.txt` records the product name, version, build number, bundle identifier, package time, git commit, and git tree state.
- `ReleaseDocs/` includes `CYCLE_9_SMOKE_TEST.md`, `CYCLE_9_RELEASE_CHECKLIST.md`, and `CYCLE_9_RELEASE_NOTES.md`.
- The zip expands into the same app-plus-docs structure without missing files.

## Launch

Run:

```bash
open artifacts/release/<latest-package>/MilsimPonyGame.app
```

Expected result:

- The HUD title reads `Cycle 9 Release Candidate`.
- The title shell includes a `Release:` line showing `v0.9.0 (9)` and the app bundle identifier.
- The title shell and settings shell include a `Content:` line that resolves to `bundled` for the packaged app.
- The overlay header shows release, bundle, content source, world, asset path, world-data path, and manifest path together.

## Demo Flow Regression

Expected result:

- `Space` or `Return` still starts the run from the briefing shell.
- `Esc` still pauses and resumes the mission cleanly.
- Failure, retry, restart, return-to-briefing, settings, and completion flows still resolve without developer intervention.
- The completion shell still reports run time, route distance, and restart count.
