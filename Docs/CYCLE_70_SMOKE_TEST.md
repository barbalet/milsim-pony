# Cycle 70 Smoke Test

Verify that the Canberra demo now behaves as a cycle `70` restore-cleanup preview pass: the active Woden-to-Belconnen route remains unchanged, while persisted review state previews what future stale-card cleanup would do without deleting anything in this build.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Cleanup Preview Validation`.
3. Confirm the HUD title reads `Cycle 70 Restore Cleanup Preview`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, and `Restore Cleanup Preview:` lines or their no-persisted-state fallbacks.

## Persist And Inspect Cleanup

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Restore Retention: keep for future prompt review`.
6. Confirm the title shell shows `Restore Cleanup Preview: no cleanup needed / review card retained`.
7. Confirm the cleanup preview does not report any deletion in this build.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm no restore prompt can be selected yet.
3. Confirm no persisted review state is deleted by this cycle.
4. Confirm starting from briefing still begins a fresh live run.
5. Confirm retry and restart behavior remains the same as cycle `69`.
6. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `70` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `70` restore-cleanup preview build.
