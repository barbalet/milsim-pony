# Cycle 71 Smoke Test

Verify that the Canberra demo now behaves as a cycle `71` restore-cleanup execution pass: the active Woden-to-Belconnen route remains unchanged, current persisted review state is retained, and stale review cards are cleared on launch before any future restore prompt can use them.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Cleanup Execution Validation`.
3. Confirm the HUD title reads `Cycle 71 Restore Cleanup Execution`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Persist And Retain Current State

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app within the freshness window.
5. Confirm the title shell shows `Restore Retention: keep for future prompt review`.
6. Confirm the title shell shows `Restore Cleanup Preview: no cleanup needed / review card retained`.
7. Confirm the title shell shows `Restore Cleanup: no cleanup needed / review card retained`.

## Stale Cleanup Guardrail

1. With an older persisted review card outside the freshness window, relaunch the app.
2. Confirm the title shell shows `Restore Cleanup: cleared stale review card`.
3. Confirm stale-card cleanup removes the old review card before any restore prompt can use it.
4. Confirm relaunch still starts from briefing and does not restore camera or checkpoint position.

## Behavior Guardrails

1. Confirm no current review card is deleted by a normal same-day relaunch.
2. Confirm no restore prompt can be selected yet.
3. Confirm starting from briefing still begins a fresh live run.
4. Confirm retry and restart behavior remains the same as cycle `70`.
5. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `71` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `71` restore-cleanup execution build.
