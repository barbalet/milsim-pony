# Cycle 81 Smoke Test

## Patrol Pair Foundation

Verify that the Canberra demo now behaves as a cycle `81` patrol-pair foundation pass: the shell advertises the new cycle, authored observer pairs carry shared route state, and the live overlay reports formation spacing before scan-state behavior is added.

## Launch And Shell

1. Build and launch `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Patrol Pair Foundation Validation`.
3. Confirm the HUD title reads `Cycle 81 Patrol Pair Foundation`.
4. Confirm the title shell still carries restore review, scoped-rifle, weapon-feel, and profiling lines from previous cycles.
5. Start the demo and confirm the live overlay includes `Patrol Pairs:`.

## Authored Pair Metadata

1. Confirm Woden, East Basin, Civic, and Belconnen observer pairs each share a patrol route ID.
2. Confirm each pair exposes `lead` and `wing` roles in the `Patrol Pairs:` line.
3. Confirm the line reports active members as `2/2` before any observer is neutralized.
4. Confirm formation spacing is reported in meters and matches the authored pair spacing.

## Relay Regression

1. Enter a paired observer lane and trigger a seeing or alerted state.
2. Confirm existing `Observer Feedback:` relay counts still update.
3. Confirm `LOS` lines still identify seeing, alerted, masked, support, and off-axis observers.
4. Neutralize one member of a pair and confirm `Patrol Pairs:` active count can drop while the remaining member stays readable.

## Map And Combat Readability

1. Open the overhead map and confirm threat markers still render for all observers.
2. Confirm contact-stop expected observer counts still agree with the paired lanes.
3. Raise the 4x scope and confirm scoped-rifle presentation from cycle `80` still works.
4. Confirm `Muzzle Feedback:` and `Profile Baseline:` remain visible in the overlay.

## Regression Checks

1. Pause, resume, restart route, and return to briefing; confirm pair state reappears after restart.
2. Confirm restore review intent remains non-executable.
3. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `81` patrol-pair foundation build.
4. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `81` label and patrol-pair metadata.
