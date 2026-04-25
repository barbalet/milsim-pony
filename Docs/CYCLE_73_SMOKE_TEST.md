# Cycle 73 Smoke Test

Verify that the Canberra demo now behaves as a cycle `73` restore-selection audit pass: the active Woden-to-Belconnen route remains unchanged, the preview-only restore target can be reviewed, and the title shell records that review without restoring checkpoint state.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Selection Audit Validation`.
3. Confirm the HUD title reads `Cycle 73 Restore Selection Audit`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Persist And Audit Selection

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app within the freshness window.
5. Confirm the title shell shows `Restore Choice: preview Restore`.
6. Confirm the title shell initially shows `Restore Selection: pending review`.
7. Activate `Review Restore Target:` and confirm the title shell updates to `Restore Selection: reviewed`.
8. Confirm the status line reports that `Start Demo` still begins fresh.

## Behavior Guardrails

1. Confirm `Review Restore Target:` does not move the camera or checkpoint position.
2. Confirm `Restore Execution Gate:` remains closed after the selection audit.
3. Confirm `Start Demo` still begins a fresh live run from the authored briefing start.
4. Confirm retry and restart behavior remains the same as cycle `72`.
5. Confirm a stale persisted review card still shows `Restore Cleanup: cleared stale review card`.
6. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `73` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `73` restore-selection audit build.
