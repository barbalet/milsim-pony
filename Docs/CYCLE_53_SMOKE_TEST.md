# Cycle 53 Smoke Test

Verify that the Canberra demo now behaves as a cycle `53` water-surface motion pass: the active Woden-to-Belconnen route remains the only bound playable route, while lake blocks use the water material and animate from the scene-authored environmental-motion controls.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Water Surface Motion Validation`.
4. Confirm the HUD title reads `Cycle 53 Water Surface Motion`.
5. Confirm route details include `Environmental Motion:` with wind, gust, vegetation, shoreline-ripple, and water-surface values.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Confirm `Route Preflight:` and `Collision Authoring:` still report without mutating active checkpoints.
4. Inspect Lake Burley Griffin surfaces from the Woden and central-basin sightlines; confirm the water texture, subtle vertex ripple, UV flow, and brighter specular response are visible without hiding route markers or observer cues.
5. Restart from a checkpoint and confirm the environmental-motion line persists after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the map footer includes `Environmental Motion:` after the collision-authoring line.
3. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `53` label and `environmentalMotion.waterSurfaceResponse`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `53` water-surface motion build.
