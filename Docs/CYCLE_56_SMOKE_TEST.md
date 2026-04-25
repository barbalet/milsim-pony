# Cycle 56 Smoke Test

Verify that the Canberra demo now behaves as a cycle `56` landmark material-breakup pass: the active Woden-to-Belconnen route remains the only bound playable route, while named Canberra landmark facades receive tint, roughness, and normal-scale variation from the scene material-breakup controls.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Landmark Material Breakup Validation`.
4. Confirm the HUD title reads `Cycle 56 Landmark Material Breakup`.
5. Confirm route details include `Material Breakup:` with generated decal count and landmark material count.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Inspect Parliament, Civic, Black Mountain/Telstra, Woden, Belconnen, gallery, museum, and library massing from route sightlines; confirm facade tone and material response vary by landmark family.
4. Raise the scope on long skyline reads; confirm landmark surfaces no longer collapse into one concrete/facade family and remain stable while panning.
5. Restart from a checkpoint and confirm route preflight, collision authoring, environmental motion, post-process, and material-breakup reporting persist after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.
3. Confirm the map footer still includes `Environmental Motion:` after the collision-authoring line.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `56` label and increased `materialBreakup.landmarkBreakupStrength`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `56` landmark material-breakup build.
