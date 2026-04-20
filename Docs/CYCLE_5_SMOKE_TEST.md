# Cycle 5 Smoke Test

## Goal

Verify that the Canberra slice now behaves like a stealth-evasion prototype with observer pressure, visible cover and route guidance, and a fail-and-retry loop from checkpoints.

## Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyDerived/Build/Products/Debug/`.

## Launch

Run:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

Expected result:

- The app launches to the Canberra bootstrap slice with the cycle `5` overlay active.
- The overlay includes an `Evasion:` section in addition to route and streaming data.
- The scene shows route beacons plus new cover/signpost/threat markers placed through the corridor.

## Detection Loop

Expected result:

- Approaching an observer lane without cover increases the `Evasion:` suspicion value.
- The `Threat:` line updates watching and in-range counts as the player moves through the slice.
- The scene background shifts warmer as suspicion rises.
- Filling the suspicion meter trips a failure state and changes the overlay to a compromised/retry prompt.

## Retry Flow

Expected result:

- After detection, movement stops and the status line reports the failure.
- Pressing `R` clears the fail state and restarts from the latest checkpoint.
- The `Threat:` line increments the failure count.
- Route progress before the last checkpoint is preserved for the retry.

## Guidance And Cover

Expected result:

- The overlay reports the nearest cover point and the nearest signpost while the route is still active.
- The added barrier, shelter, and service-lane cover pieces block movement and create readable hiding spots.
- Signpost markers continue to point the player toward the escape corridor and final exit.

## Regression Check

Expected result:

- `W A S D`, mouse look, and `Shift` still work for normal traversal when not failed.
- Checkpoint completion still advances the route in order.
- Reaching the final checkpoint still completes the route and does not leave the player stuck in fail state.
