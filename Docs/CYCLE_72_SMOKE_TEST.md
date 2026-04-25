# Cycle 72 Smoke Test

Verify that the Canberra demo now behaves as a cycle `72` restore-choice preview pass: the active Woden-to-Belconnen route remains unchanged, stale review cards are still cleaned up, and a valid current review card can surface a preview-only restore target without restoring checkpoint state.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Choice Preview Validation`.
3. Confirm the HUD title reads `Cycle 72 Restore Choice Preview`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Persist And Preview Choice

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app within the freshness window.
5. Confirm the title shell shows `Restore Choice: preview Restore`.
6. Confirm the title menu shows a `Review Restore Target:` action for the saved next checkpoint.
7. Activate `Review Restore Target:` and confirm the status line reports that `Start Demo` still begins fresh.

## Behavior Guardrails

1. Confirm `Review Restore Target:` does not move the camera or checkpoint position.
2. Confirm `Start Demo` still begins a fresh live run from the authored briefing start.
3. Confirm retry and restart behavior remains the same as cycle `71`.
4. Confirm a stale persisted review card still shows `Restore Cleanup: cleared stale review card`.
5. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `72` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `72` restore-choice preview build.
