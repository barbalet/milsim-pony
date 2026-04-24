# Cycle 36 Smoke Test

Verify that the Canberra demo now behaves as a cycle `36` staged-route loader-metrics pass: the active Woden-to-Belconnen route remains the only bound playable route, while the staged alternate route exposes marker count, planned distance, and sector footprint.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Staged Route Metrics Validation`.
4. Confirm the HUD title reads `Cycle 36 Staged Route Loader Metrics`.
5. Confirm the briefing includes:
   - `Active Route: Canberra Combat-Lane Rehearsal / staged East Basin To Belconnen Probe`
   - `Staged Route:` with marker count, planned distance, and sector count
   - `Selection: briefing-locked preview / selection-ready metadata`
   - `Ownership: ownership split ready / 2 shared / 5 alternate-owned`
6. Confirm the planning notes mention preserving the cycle `35` active-route staging.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details report `alternate route metrics staged for loader binding`.
4. Confirm the alternate route is not yet the live checkpoint sequence.
5. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `35`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Active Route:` line reporting:
   - `Canberra Combat-Lane Rehearsal`
   - `staged East Basin To Belconnen Probe`
   - `primary route bound`
   - `alternate route metrics staged for loader binding`
5. Confirm the `Alt Preview:` line reports the preview marker count, planned distance in meters, sector count, `ownership split ready`, and `shared 2 / owned 5`.
6. Confirm the yellow active route path, green completed route segments, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `36` label and `alternate route metrics staged for loader binding`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `36` staged-route loader-metrics build.
