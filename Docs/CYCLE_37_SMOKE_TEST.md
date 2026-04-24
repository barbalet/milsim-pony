# Cycle 37 Smoke Test

Verify that the Canberra demo now behaves as a cycle `37` alternate-route binding-gate pass: the active Woden-to-Belconnen route remains the only bound playable route, while the staged alternate route reports that its loader validation gate is eligible but not switched live.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Binding Gate Validation`.
4. Confirm the HUD title reads `Cycle 37 Alternate Route Binding Gate`.
5. Confirm the briefing includes:
   - `Active Route: Canberra Combat-Lane Rehearsal / staged East Basin To Belconnen Probe`
   - `Route Validation: staged alternate route eligible; live switch disabled`
   - `Staged Route:` with marker count, planned distance, and sector count
   - `Binding Gate: loader gate eligible`
6. Confirm the planning notes mention preserving the cycle `36` route metrics.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details report `alternate route binding gate validated`.
4. Confirm the alternate route is not yet the live checkpoint sequence.
5. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `36`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Active Route:` line reporting:
   - `Canberra Combat-Lane Rehearsal`
   - `staged East Basin To Belconnen Probe`
   - `primary route bound`
   - `alternate route binding gate validated`
5. Confirm the map footer includes `Route Validation:` with the staged-route eligibility rule.
6. Confirm the `Alt Preview:` line still reports the preview marker count, planned distance in meters, sector count, `ownership split ready`, and `shared 2 / owned 5`.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `37` label and `alternate route binding gate validated`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `37` alternate-route binding-gate build.
