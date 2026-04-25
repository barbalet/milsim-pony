# Cycle 40 Smoke Test

Verify that the Canberra demo now behaves as a cycle `40` alternate-route activation-guard pass: the active Woden-to-Belconnen route remains the only bound playable route, while the staged alternate route reports that activation is guarded until a fresh run boundary can bind the selected alternate checkpoint sequence.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Activation Guard Validation`.
4. Confirm the HUD title reads `Cycle 40 Alternate Route Activation Guard`.
5. Confirm the briefing includes:
   - `Active Route: Canberra Combat-Lane Rehearsal / staged East Basin To Belconnen Probe`
   - `Route Validation: staged alternate route eligible; live switch disabled`
   - `Route Selection: briefing selection locked; live switch disabled`
   - `Route Activation: activation guard armed; primary route still live`
   - `Route Handoff: restart-safe handoff planned; checkpoint order unchanged`
   - `Binding Gate: loader gate eligible`
6. Confirm the planning notes mention preserving the cycle `39` briefing-only selection lock.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details report `alternate route activation guard staged`.
4. Confirm the alternate route is still not the live checkpoint sequence.
5. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `39`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend still includes `Alt Preview`.
3. Confirm the blue dashed alternate-route preview path still draws over the candidate checkpoints.
4. Confirm the map footer includes an `Active Route:` line reporting:
   - `Canberra Combat-Lane Rehearsal`
   - `staged East Basin To Belconnen Probe`
   - `primary route bound`
   - `alternate route activation guard staged`
5. Confirm the map footer includes `Route Selection:` with the briefing-only route-choice rule.
6. Confirm the map footer includes `Route Activation:` with the fresh-run-boundary activation rule.
7. Confirm the map footer still includes `Route Handoff:` with the briefing-or-restart boundary rule.
8. Confirm the `Alt Preview:` line reports the preview marker count, planned distance in meters, sector count, `briefing-locked candidate`, `activation guard ready; not live-bound`, `ownership split ready`, and `shared 2 / owned 5`.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `40` label and `activation guard armed; primary route still live`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `40` alternate-route activation-guard build.
