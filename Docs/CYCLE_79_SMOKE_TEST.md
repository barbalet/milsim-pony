# Cycle 79 Smoke Test

## Weapon Feel And Profiling Reset

Verify that the Canberra demo now behaves as a cycle `79` weapon-feel and profiling pass: the shell advertises the new cycle, the rifle loop exposes muzzle placeholder and recoil recovery telemetry, and the overlay carries a formal frame/core/LOS/world profiling baseline.

## Launch And Shell

1. Build and launch `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Weapon Feel Profiling Validation`.
3. Confirm the HUD title reads `Cycle 79 Weapon Feel And Profiling Reset`.
4. Confirm the title shell still shows the restore review and cleanup lines from cycles `71` through `78`.
5. Confirm the overlay includes `Profile Baseline:` after the renderer starts submitting frames.

## Live Rifle Feedback

1. Start the demo from the briefing shell.
2. Fire once before raising the scope.
3. Confirm `Weapon:` reports the shot count, last shot classification, distance, and rifle cycle.
4. Confirm `Muzzle Feedback:` reports a non-idle flash percentage, recoil recovery percentage, cooldown state, and last shot classification.
5. Wait for the bolt cycle to settle and confirm `Muzzle Feedback:` decays to `flash 0%` and `recoil 0% settled`.

## Hit, Miss, And Impact Readability

1. Raise the 4x scope at a contact lane and aim at an observer.
2. Fire and confirm the status line reports a confirmed observer hit if the prediction intersects the target.
3. Fire at nearby cover or ground and confirm the same loop reports `blocker strike`, `ground strike`, or `clear miss` rather than only a generic shot line.
4. Confirm shot, impact, hit-confirm, and dry-click audio cues still play as they did before this cycle.

## Profiling Baseline

1. Move through at least one checkpoint while the overlay is visible.
2. Confirm `Frame:` reports frame milliseconds, FPS, and drawable count.
3. Confirm `Profiler:` reports simulation, movement, LOS, and LOS sample counts.
4. Confirm `Profile Baseline:` combines frame timing with core step counts, LOS counts, sector count, blocker count, and surface count.
5. Open the map and raise/lower the scope; confirm the profiling lines continue to update and do not hide weapon telemetry.

## Regression Checks

1. Confirm observer feedback audio and LOS lines still update when watchers see, relay, or lose the player.
2. Confirm checkpoint restart, pause/resume, and return-to-briefing still clear live input safely.
3. Confirm restore review intent remains non-executable; `Restore Review Intent:` is still reporting review state, not enabling a checkpoint restore.
4. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `79` weapon-feel profiling build.
5. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `79` label and combat-rehearsal summary.
