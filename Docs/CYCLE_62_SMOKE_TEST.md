# Cycle 62 Smoke Test

Verify that the Canberra demo now behaves as a cycle `62` restore-target preview pass: the active Woden-to-Belconnen route remains the only bound playable route, while the persisted review-resume card reports the future checkpoint resume target without moving the player on launch.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Restore Target Preview Validation`.
3. Confirm the HUD title reads `Cycle 62 Restore Target Preview`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, and `Restore Preview:` lines or their no-persisted-state fallbacks.

## Persist And Preview

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Review Guardrail: stored review card valid`.
6. Confirm the title shell shows `Restore Preview: future resume target`.
7. Confirm the restore-preview line still says launch starts fresh.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm starting from briefing still begins a fresh live run.
3. Confirm retry and restart behavior remains the same as cycle `61`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `62` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `62` restore-target preview build.
