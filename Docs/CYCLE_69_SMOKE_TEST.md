# Cycle 69 Smoke Test

Verify that the Canberra demo now behaves as a cycle `69` restore-retention policy pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports whether a stored card should be kept for future prompt review or marked as a future discard candidate.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Retention Policy Validation`.
3. Confirm the HUD title reads `Cycle 69 Restore Retention Policy`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, and `Restore Retention:` lines or their no-persisted-state fallbacks.

## Persist And Inspect Retention

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Restore Freshness: current` for a recent persisted card.
6. Confirm the title shell shows `Restore Retention: keep for future prompt review`.
7. Confirm the retention line still says `no discard in this build`.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm no restore prompt can be selected yet.
3. Confirm no persisted review state is deleted by this cycle.
4. Confirm starting from briefing still begins a fresh live run.
5. Confirm retry and restart behavior remains the same as cycle `68`.
6. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `69` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `69` restore-retention policy build.
