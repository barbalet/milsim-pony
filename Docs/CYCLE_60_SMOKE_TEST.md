# Cycle 60 Smoke Test

Verify that the Canberra demo now behaves as a cycle `60` review-resume card pass: the active Woden-to-Belconnen route remains the only bound playable route, while the persisted last-review record includes next-checkpoint and capture-context metadata for the next launch shell.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Review Resume Card Validation`.
3. Confirm the HUD title reads `Cycle 60 Review Resume Card`.
4. Confirm the title shell shows either `Last Session:` and `Review Resume:` lines or their no-persisted-state fallbacks.

## Persist Capture Context

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and raise/lower the scope during the route.
4. Pause or continue until the overlay has refreshed after the checkpoint.
5. Quit and relaunch the app.
6. Confirm the title shell shows `Last Session:` with checkpoint count, difficulty, current sector, and route state.
7. Confirm the title shell also shows `Review Resume:` with the next checkpoint, review-pack context, map state, and scope state.

## Compatibility Guardrails

1. Confirm older cycle `59` persisted records still load instead of crashing or clearing settings.
2. Confirm relaunch does not automatically restore camera or checkpoint position yet.
3. Confirm starting from briefing still begins a fresh live run.
4. Confirm retry and restart behavior remains the same as cycle `59`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `60` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `60` review-resume card build.
