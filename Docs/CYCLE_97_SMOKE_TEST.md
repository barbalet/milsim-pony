# Cycle 97 Smoke Test - Tester Distribution Pipeline

Verify that the Canberra demo now behaves as a cycle `97` tester-distribution pass: the route remains stable, packaging validation is retained, tester handoff checks are scripted, notarization blockers are explicit, and SDF UI migration is scoped for later polish.

## Distribution Check

From the repository root, run:

```bash
Tools/package_release.sh --check-distribution
```

- Confirm the command reports `Release inputs validated`.
- Confirm it reports `Tester distribution check`.
- Confirm it identifies the tester channel, archive pattern, and tester guide.
- Confirm it reports whether `xcrun notarytool` is available.

## Package Validation

From the repository root, run:

```bash
Tools/package_release.sh --validate-only
```

- Confirm the version policy is `0.97.0` with build `97`.
- Confirm the world manifest, coordinate-system file, scene file, and all sector files lint successfully.
- Confirm release docs include `README.md`, `Docs/CYCLE_97_SMOKE_TEST.md`, `Docs/TESTER_DISTRIBUTION_PIPELINE.md`, and `Docs/DEVELOPMENT_BACKLOG.md`.

## In-App Readout

- Launch the build and confirm the briefing shell identifies `Canberra Tester Distribution Pipeline`.
- Confirm the mission overlay reports `Tester Delivery:` with the scripted status, channel, notarization status, CI plan, checklist, SDF UI scope, and smoke command.
- Confirm the overhead-map footer includes `Tester Delivery:` after `Packaging:`.

## Tester Handoff Guide

- Open `Docs/TESTER_DISTRIBUTION_PIPELINE.md`.
- Confirm it documents version/archive policy, distribution gate, package gate, notarization plan, CI plan, and SDF UI scope.

## Regression

- Confirm `Packaging:`, `LOD Reflection:`, `CSM Profile:`, `Scope Calibration:`, route progress, and map route markers remain visible.
- Confirm the app still loads the authored Canberra world manifest rather than falling back to the procedural error scene.
