# Cycle 61 Smoke Test

Verify that the Canberra demo now behaves as a cycle `61` review-persistence guardrail pass: the active Woden-to-Belconnen route remains the only bound playable route, while the persisted review-resume card reports whether stored checkpoint progress is valid before any future restore work uses it.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Review Persistence Guardrail Validation`.
3. Confirm the HUD title reads `Cycle 61 Review Persistence Guardrails`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, and `Review Guardrail:` lines or their no-persisted-state fallbacks.

## Persist And Validate

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Review Guardrail: stored review card valid`.
6. Confirm the guardrail line still says launch starts fresh until checkpoint restore exists.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm starting from briefing still begins a fresh live run.
3. Confirm retry and restart behavior remains the same as cycle `60`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `61` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `61` review-persistence guardrail build.
