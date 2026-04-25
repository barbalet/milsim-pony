# Cycle 68 Smoke Test

Verify that the Canberra demo now behaves as a cycle `68` restore-freshness policy pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports whether the stored card is inside the 24-hour review window before any future restore prompt can trust it.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Freshness Policy Validation`.
3. Confirm the HUD title reads `Cycle 68 Restore Freshness Policy`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Execution Gate:`, `Restore Audit:`, and `Restore Freshness:` lines or their no-persisted-state fallbacks.

## Persist And Inspect Freshness

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Restore Audit:` with saved-age details.
6. Confirm the title shell shows `Restore Freshness: current` for a recent persisted card.
7. Confirm the freshness line names the `86400s` review window.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm no restore prompt can be selected yet.
3. Confirm starting from briefing still begins a fresh live run.
4. Confirm retry and restart behavior remains the same as cycle `67`.
5. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `68` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `68` restore-freshness policy build.
