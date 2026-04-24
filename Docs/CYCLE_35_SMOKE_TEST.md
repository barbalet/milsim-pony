# Cycle 35 Smoke Test

Verify that the Canberra demo now behaves as a cycle `35` active-route loader-staging pass: the active Woden-to-Belconnen route remains the only bound playable route, the alternate preview still draws, and the staged alternate route is visible to the briefing and map as loader-ready metadata.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Active Route Loader Validation`.
4. Confirm the HUD title reads `Cycle 35 Active Route Loader Staging`.
5. Confirm the briefing includes:
   - `Active Route: Canberra Combat-Lane Rehearsal / staged East Basin To Belconnen Probe`
   - `Selection: briefing-locked preview / selection-ready metadata`
   - `Ownership: ownership split ready / 2 shared / 5 alternate-owned`
6. Confirm the planning notes mention preserving the cycle `32` preview path, cycle `33` selection readiness, and cycle `34` checkpoint ownership.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details report `primary route bound` and `alternate route staged for loader binding`.
4. Confirm the alternate route is not yet the live checkpoint sequence.
5. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `34`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Active Route:` line reporting:
   - `Canberra Combat-Lane Rehearsal`
   - `staged East Basin To Belconnen Probe`
   - `primary route bound`
   - `alternate route staged for loader binding`
5. Confirm the `Alt Preview:` line still reports `ownership split ready` and `shared 2 / owned 5`.
6. Confirm the yellow active route path, green completed route segments, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `35` label and a non-empty `routeSelection` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `35` active-route loader-staging build.
