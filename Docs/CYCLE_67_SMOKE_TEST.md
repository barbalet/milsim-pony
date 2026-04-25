# Cycle 67 Smoke Test

Verify that the Canberra demo now behaves as a cycle `67` restore-audit trail pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports schema, checkpoint progress, target, identity, and save-age details before any future restore execution can trust it.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Audit Trail Validation`.
3. Confirm the HUD title reads `Cycle 67 Restore Audit Trail`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Execution Gate:`, and `Restore Audit:` lines or their no-persisted-state fallbacks.

## Persist And Inspect Audit

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Restore Execution Gate: closed / restore action not bound in this build`.
6. Confirm the title shell shows `Restore Audit:` with schema, checkpoint progress, target, identity, and saved-age details.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm no restore prompt can be selected yet.
3. Confirm starting from briefing still begins a fresh live run.
4. Confirm retry and restart behavior remains the same as cycle `66`.
5. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `67` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `67` restore-audit trail build.
