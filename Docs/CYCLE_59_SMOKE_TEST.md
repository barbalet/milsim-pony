# Cycle 59 Smoke Test

Verify that the Canberra demo now behaves as a cycle `59` review-state persistence pass: the active Woden-to-Belconnen route remains the only bound playable route, while the app stores a compact last-review record that can be shown on the next launch shell.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Review State Persistence Validation`.
3. Confirm the HUD title reads `Cycle 59 Review State Persistence`.
4. Confirm route details still include `Session Persistence:`.
5. Confirm the title shell shows either `Last Session: no persisted review state yet` or a stored `Last Session:` line.

## Persist A Review Record

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open and close the map once.
4. Pause the demo and confirm the session-persistence line remains visible.
5. Quit and relaunch the app.
6. Confirm the title shell now shows `Last Session:` with checkpoint count, difficulty, current sector, and route state.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm starting from briefing still begins a fresh live run.
3. Confirm retry and restart behavior remains the same as cycle `58`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `59` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `59` review-state persistence build.
