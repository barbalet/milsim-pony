# Cycle 34 Smoke Test

Verify that the Canberra demo now behaves as a cycle `34` alternate-route checkpoint-ownership pass: the active Woden-to-Belconnen route remains playable, the alternate preview still draws, and the candidate route now reports shared and alternate-owned checkpoint groups.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Ownership Validation`.
4. Confirm the HUD title reads `Cycle 34 Alternate Route Checkpoint Ownership`.
5. Confirm the briefing includes both `Selection:` and `Ownership:` lines.
6. Confirm the planning notes mention preserving the cycle `32` preview path and cycle `33` selection readiness.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details include:
   - `Alt Route: East Basin To Belconnen Probe`
   - `Selection: briefing-locked preview / selection-ready metadata`
   - `Ownership: ownership split ready / 2 shared / 5 alternate-owned`
4. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `33`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Alt Preview:` line reporting:
   - `East Basin To Belconnen Probe`
   - `preview-candidate`
   - `ownership split ready`
   - `shared 2 / owned 5`
   - `selectable after live route loader can bind alternate checkpoint ownership`
5. Confirm the yellow active route path, green completed route segments, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `34` label plus `checkpointOwnershipStatus`, `sharedCheckpointIDs`, and `exclusiveCheckpointIDs` in `alternateRoutes`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `34` alternate-route checkpoint-ownership build.
