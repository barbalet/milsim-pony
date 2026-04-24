# Cycle 32 Smoke Test

Verify that the Canberra demo now behaves as a cycle `32` alternate-route preview pass: the active Woden-to-Belconnen route remains playable, while the overhead map draws the second rehearsal route candidate as a distinct preview path.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Alternate Route Preview Validation`.
4. Confirm the HUD title reads `Cycle 32 Alternate Route Preview`.
5. Confirm the planning notes mention the cycle `32` map preview path and the carried cycle `31` route authoring data.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the active route still begins on the Woden-to-Belconnen line.
3. Confirm route details include an `Alternate Routes:` line.
4. Confirm route details name `East Basin To Belconnen Probe` as the preview candidate.
5. Confirm checkpoint retry, mission phase hooks, observer audio, scope feedback, and the active route path still behave as in cycle `31`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the legend includes `Alt Preview`.
3. Confirm the map draws a blue dashed alternate-route preview over the candidate checkpoints.
4. Confirm the map footer includes an `Alt Preview:` line reporting:
   - `East Basin To Belconnen Probe`
   - `preview-candidate`
   - the preview marker count
   - `East Basin Lookout -> Ginninderra Drive Review`
5. Confirm the yellow active route path, green completed route segments, checkpoint progress, mission line, contact line, and threat counts still render.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `32` label and `preview-candidate` alternate route type.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `32` alternate-route preview build.
