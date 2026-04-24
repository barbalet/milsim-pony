# Cycle 33 Smoke Test

Verify that the Canberra demo now behaves as a cycle `33` alternate-route selection-readiness pass: the active Woden-to-Belconnen route remains playable, the cycle `32` preview path still draws, and the candidate route now exposes explicit selection mode, readiness, and activation rules.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Selection Validation`.
4. Confirm the HUD title reads `Cycle 33 Alternate Route Selection Readiness`.
5. Confirm the briefing includes a `Selection:` line.
6. Confirm the planning notes mention preserving the cycle `32` overhead-map preview path.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details include:
   - `Alternate Routes:`
   - `Alt Route: East Basin To Belconnen Probe`
   - `Selection: briefing-locked preview / selection-ready metadata`
4. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `32`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Alt Preview:` line reporting:
   - `East Basin To Belconnen Probe`
   - `preview-candidate`
   - the preview marker count
   - `briefing-locked preview`
   - `selection-ready metadata`
   - `selectable after checkpoint ownership is split from the active route`
5. Confirm the yellow active route path, green completed route segments, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `33` label plus `selectionMode`, `selectionStatus`, and `activationRule` in `alternateRoutes`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `33` alternate-route selection-readiness build.
