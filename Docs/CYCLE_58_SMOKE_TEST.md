# Cycle 58 Smoke Test

Verify that the Canberra demo now behaves as a cycle `58` session-persistence readiness pass: the active Woden-to-Belconnen route remains the only bound playable route, while the title shell, pause shell, route details, and overhead map report the save/resume contract that future cycles will persist.

## Launch

1. Build and run `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Session Persistence Readiness Validation`.
3. Confirm the HUD title reads `Cycle 58 Session Persistence Readiness`.
4. Confirm route details include `Session Persistence:` after the environmental fidelity lines.
5. Confirm the line reports starts, checkpoints, alternate routes, review stops, and mission hooks.

## Live Route

1. Start the route from briefing.
2. Move through at least two checkpoints.
3. Confirm checkpoint progress, observer pressure, scope feedback, and mission hook text behave as in cycle `57`.
4. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
5. Confirm no automatic save/load prompt appears yet.

## Pause And Resume Shell

1. Pause mid-route.
2. Confirm the pause shell includes `Session Persistence:`.
3. Resume and confirm the current live run continues without resetting progress.
4. Restart from the shell and confirm the run resets from a fresh rehearsal start.

## Map Review

1. Open the overhead map.
2. Confirm the map footer includes `Session Persistence:` after `Surface Fidelity:`.
3. Confirm alternate-route preview, collision authoring, environmental motion, and surface-fidelity lines remain visible.

## Data Check

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `58` label and `sessionPersistence` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `58` session-persistence readiness build.
