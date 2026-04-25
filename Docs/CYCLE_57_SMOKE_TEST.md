# Cycle 57 Smoke Test

Verify that the Canberra demo now behaves as a cycle `57` surface-fidelity closeout pass: the active Woden-to-Belconnen route remains the only bound playable route, while wind, vegetation, water, SSAO, road decals, and landmark material breakup are reported as one reviewable surface stack.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Surface Fidelity Closeout Validation`.
4. Confirm the HUD title reads `Cycle 57 Surface Fidelity Closeout`.
5. Confirm route details include both `Environmental Motion:` and `Surface Fidelity:`.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Inspect vegetation motion, water motion, road scuffs, landmark facade variation, and contact depth as one combined readability pass.
4. Raise the scope on lake, road, and skyline stops; confirm the surface stack stays readable without obscuring route markers, observer cues, or district silhouettes.
5. Restart from a checkpoint and confirm route preflight, collision authoring, environmental motion, post-process, material-breakup, and surface-fidelity reporting persist after recovery.

## Overhead Map

1. Open the overhead map.
2. Confirm the map footer includes `Environmental Motion:` and `Surface Fidelity:` after the collision-authoring line.
3. Confirm the Woden-to-Belconnen route polyline, alternate-route preview, and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `57` label and `surfaceFidelity` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `57` surface-fidelity closeout build.
