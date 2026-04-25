# Cycle 54 Smoke Test

Verify that the Canberra demo now behaves as a cycle `54` screen-space surface-depth pass: the active Woden-to-Belconnen route remains the only bound playable route, while the post-process path uses depth-buffer contact darkening to improve terrain, bridge, lake-edge, and block grounding.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Screen-Space Surface Depth Validation`.
4. Confirm the HUD title reads `Cycle 54 Screen-Space Surface Depth`.
5. Confirm route details still include the environmental-motion line and a `Post:` line with SSAO strength and radius.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Inspect road edges, bridge slabs, lake edges, low concrete blocks, and terrain transitions; confirm contact darkening adds grounding without crushing the scene.
4. Raise the scope on skyline and lake-edge stops; confirm the contact-depth pass remains stable and does not shimmer aggressively during slow camera movement.
5. Restart from a checkpoint and confirm route preflight, collision authoring, environmental motion, and post-process reporting persist after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.
3. Confirm the map footer still includes `Environmental Motion:` after the collision-authoring line.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `54` label and `postProcess.ssaoStrength`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `54` screen-space surface-depth build.
