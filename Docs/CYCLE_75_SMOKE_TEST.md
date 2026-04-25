# Cycle 75 Smoke Test

Verify that the Canberra demo now behaves as a cycle `75` restore boundary reset pass: the active Woden-to-Belconnen route remains unchanged, reviewed restore targets are still non-executable, and briefing or restart boundaries clear in-memory restore review state.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Boundary Reset Validation`.
3. Confirm the HUD title reads `Cycle 75 Restore Boundary Reset`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Fresh Start:`, `Restore Boundary Reset:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Review And Clear Boundary

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app within the freshness window.
5. Activate `Review Restore Target:` and confirm `Restore Selection: reviewed`.
6. Activate `Start Demo` and confirm `Restore Fresh Start: confirmed over`.
7. Return to briefing.
8. Confirm the title shell shows `Restore Boundary Reset: cleared`.
9. Confirm `Restore Selection:` returns to `pending review` for the persisted card.

## Behavior Guardrails

1. Confirm boundary reset does not delete a current persisted review card.
2. Confirm `Restore Execution Gate:` remains closed after boundary reset.
3. Confirm no checkpoint, camera position, or route progress is restored.
4. Confirm restart boundaries also clear reviewed restore-target state.
5. Confirm retry behavior remains the same as cycle `74`.
6. Confirm a stale persisted review card still shows `Restore Cleanup: cleared stale review card`.
7. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `75` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `75` restore boundary reset build.
