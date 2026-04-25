# Cycle 55 Smoke Test

Verify that the Canberra demo now behaves as a cycle `55` road material-breakup pass: the active Woden-to-Belconnen route remains the only bound playable route, while authored road strips receive low-profile mesh scuff decals that make the basin road network feel less diagrammatic.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Road Material Breakup Validation`.
4. Confirm the HUD title reads `Cycle 55 Road Material Breakup`.
5. Confirm route details include `Material Breakup:` with road density, scuff strength, landmark strength, and generated decal count.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Inspect Commonwealth Avenue, Parkes Way, Kings Avenue, Woden, Black Mountain, and Belconnen road strips; confirm subtle dark repair/scuff decals sit on the road surface.
4. Raise the scope on long road reads; confirm decals add breakup without creating obvious shimmer, route-marker occlusion, or collision changes.
5. Restart from a checkpoint and confirm route preflight, collision authoring, environmental motion, post-process, and material-breakup reporting persist after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.
3. Confirm the map footer still includes `Environmental Motion:` after the collision-authoring line.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `55` label and `materialBreakup` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `55` road material-breakup build.
