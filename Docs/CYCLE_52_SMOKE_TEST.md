# Cycle 52 Smoke Test

Verify that the Canberra demo now behaves as a cycle `52` environmental-motion groundwork pass: the active Woden-to-Belconnen route remains the only bound playable route, while vegetation and lake-edge terrain motion are driven from scene-authored wind controls.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Environmental Motion Groundwork Validation`.
4. Confirm the HUD title reads `Cycle 52 Environmental Motion Groundwork`.
5. Confirm route details include `Environmental Motion:` with wind, gust, vegetation, and shoreline-ripple values.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Confirm `Route Preflight:` and `Collision Authoring:` still report without mutating active checkpoints.
4. Watch ground-cover and shoreline-adjacent terrain layers while moving or scoped; confirm motion is present but does not obscure route markers or observer cues.
5. Restart from a checkpoint and confirm the environmental-motion line persists after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the map footer includes `Environmental Motion:` after the collision-authoring line.
3. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `52` label and `environmentalMotion` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `52` environmental-motion groundwork build.
