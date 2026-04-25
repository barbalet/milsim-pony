# Cycle 74 Smoke Test

Verify that the Canberra demo now behaves as a cycle `74` restore fresh-start guard pass: the active Woden-to-Belconnen route remains unchanged, restore target review is still preview-only, and pressing `Start Demo` after reviewing a restore target records that a fresh run was intentionally chosen.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Fresh Start Guard Validation`.
3. Confirm the HUD title reads `Cycle 74 Restore Fresh Start Guard`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Fresh Start:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Persist, Review, And Start Fresh

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app within the freshness window.
5. Confirm the title shell shows `Restore Selection: pending review`.
6. Activate `Review Restore Target:` and confirm the title shell updates to `Restore Selection: reviewed`.
7. Confirm the title shell shows `Restore Fresh Start: awaiting Start Demo`.
8. Activate `Start Demo`.
9. Confirm the live overlay shows `Restore Fresh Start: confirmed over`.
10. Confirm the status line reports that restore remains disabled.

## Behavior Guardrails

1. Confirm `Start Demo` after restore-target review still begins a fresh run from the authored briefing start.
2. Confirm `Restore Execution Gate:` remains closed after the fresh-start guard is recorded.
3. Confirm no checkpoint, camera position, or route progress is restored.
4. Confirm retry and restart behavior remains the same as cycle `73`.
5. Confirm a stale persisted review card still shows `Restore Cleanup: cleared stale review card`.
6. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `74` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `74` restore fresh-start guard build.
