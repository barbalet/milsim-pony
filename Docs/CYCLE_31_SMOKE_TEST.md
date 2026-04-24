# Cycle 31 Smoke Test

Verify that the Canberra demo now behaves as a cycle `31` second-route authoring start: the active Woden-to-Belconnen route remains playable, while the HUD and Canberra map expose a reviewable alternate rehearsal route scaffold.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Authoring Validation`.
4. Confirm the HUD title reads `Cycle 31 Second Rehearsal Route Authoring Start`.
5. Confirm the planning notes mention second-route authoring and the carried cycle `30` mission-script baseline.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details include an `Alternate Routes:` line.
4. Confirm route details name `East Basin To Belconnen Probe` as an authoring candidate.
5. Confirm checkpoint retry, mission phase hooks, observer audio, and scope feedback still behave as in cycle `30`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the map footer includes an `Alt Route:` line.
3. Confirm the alternate route line reports:
   - `East Basin To Belconnen Probe`
   - `authoring-candidate`
   - `East Basin Lookout -> Ginninderra Drive Review`
4. Confirm the active route path, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries a non-empty `alternateRoutes` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `31` alternate route authoring build.
