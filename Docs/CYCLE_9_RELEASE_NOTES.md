# Cycle 9 Release Notes

## Release Candidate `0.9.0` Build `9`

The Canberra demo now ships as a release-candidate package that can be built, zipped, and reviewed outside the development workspace.

## Highlights

- Added explicit release metadata so the app reports `v0.9.0 (9)` and `com.milsimpony.game` in the shell.
- Locked launch-path resolution to prefer bundled resources, which keeps packaged builds on their own shipped assets and world manifest instead of silently reading the workspace copy.
- Added a release packaging script that emits a timestamped artifact directory, a zip, and a build manifest.
- Bundled the smoke test, release checklist, and release notes directly into the review package.
- Carried forward cycle `8` hitch-hardening and thin-occluder detection fixes into the release candidate baseline.

## Demo Scope

- Start at State Circle South Verge.
- Route through State Circle Cutthrough, Cross Street Junction, Deakin Service Lane, and Extraction Canopy.
- Support title, pause, settings, fail, retry, restart, return-to-briefing, and completion shells in one session.

## Reviewer Notes

- The packaged app should report `Content: bundled` when launched from the release artifact.
- Use `Docs/CYCLE_9_SMOKE_TEST.md` and `Docs/CYCLE_9_RELEASE_CHECKLIST.md` as the sign-off path for outside review.
