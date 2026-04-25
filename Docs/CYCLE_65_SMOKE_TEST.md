# Cycle 65 Smoke Test

Verify that the Canberra demo now behaves as a cycle `65` manual-restore prompt-contract pass: the active Woden-to-Belconnen route remains the only bound playable route, while persisted review state reports the future restore-or-start-fresh prompt copy without enabling restore behavior.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Manual Restore Prompt Contract Validation`.
3. Confirm the HUD title reads `Cycle 65 Manual Restore Prompt Contract`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, and `Manual Restore Prompt:` lines or their no-persisted-state fallbacks.

## Persist And Preview Prompt

1. Start the route from briefing.
2. Move through at least one checkpoint.
3. Open the overhead map and pause after the overlay refreshes.
4. Quit and relaunch the app.
5. Confirm the title shell shows `Manual Restore Arm: armed for future prompt`.
6. Confirm the title shell shows `Manual Restore Prompt: future choice Restore`.
7. Confirm the prompt line still says `start fresh locked`.

## Behavior Guardrails

1. Confirm relaunch does not automatically restore camera or checkpoint position yet.
2. Confirm no restore prompt can be selected yet.
3. Confirm starting from briefing still begins a fresh live run.
4. Confirm retry and restart behavior remains the same as cycle `64`.
5. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `65` label and updated `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `65` manual-restore prompt-contract build.
