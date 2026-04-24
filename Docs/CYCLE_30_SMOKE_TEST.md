# Cycle 30 Smoke Test

Verify that the Canberra demo now behaves as a cycle `30` mission-script and checkpoint-hook pass: the shell advertises the new framing, route checkpoints expose mission phase hooks, and the map/HUD agree on the next trigger without changing the Woden-to-Belconnen rehearsal route.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Mission Hook Validation`.
4. Confirm the HUD title reads `Cycle 30 Mission Script And Checkpoint Hooks`.
5. Confirm the planning notes mention mission-script hooks, checkpoint trigger conditions, and the carried cycle `29` observer-audio baseline.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Confirm the route or briefing details include a `Mission Script:` line with checkpoint hook count.
3. Move to `Woden Scope Perch` and confirm the route details include:
   - `Mission: Observe`
   - `Trigger: Enter the perch radius with observer pressure active.`
4. Continue to `State Circle Transfer` and confirm the active mission phase changes to `Transfer`.
5. Confirm observer audio, checkpoint retry, and full restart still behave as in cycle `29`.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the footer includes a `Mission:` line.
3. Confirm the mission line names the current phase, objective, trigger, and map code.
4. Advance to a checkpoint with a different mission phase and confirm the map updates to the new hook.
5. Confirm comparison, contact, threat, atlas, and position lines still render.

## Completion

1. Complete the route through `Ginninderra Drive Review`.
2. Confirm the completion summary includes the mission-script hook count.
3. Confirm the final map mission line reports the mission hook route as complete.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries a `missionScript` block with non-empty `phases`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `30` mission hook validation build.
