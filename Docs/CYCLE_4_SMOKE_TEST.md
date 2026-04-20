# Cycle 4 Smoke Test

## Goal

Verify that the Canberra slice now supports an end-to-end escape corridor with checkpoint progress, restart-to-checkpoint flow, and sector/culling readouts.

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

- The app launches to the `Cycle 4 Escape Slice` overlay.
- The overlay reports `Parliament House District Graybox`.
- The overlay includes a route section for `Deakin South Escape`.
- The scene shows the district slice with the extended corridor content loaded through four sectors.

## Route Flow

Expected result:

- The overlay starts at `Route: 0 / 4 checkpoints`.
- Moving south from `State Circle South Verge` reaches the route checkpoints in order.
- The `Next:` route line updates to the upcoming checkpoint label and distance.
- Reaching the final checkpoint updates the route summary to a completion state.

## Restart Loop

Expected result:

- Pressing `R` restarts the run from the most recently reached checkpoint.
- Before any checkpoint is reached, `R` returns the player to the initial spawn.
- After route completion, `R` starts a fresh run from the initial spawn.
- The overlay updates the restart count in `Route Metrics`.

## Streaming And Visibility

Expected result:

- The overlay shows `Chunks:` with active versus total sectors.
- The overlay shows `Active:` and `Current Sector:` for the player location.
- The overlay shows `Visibility:` with drawn versus culled drawables.
- Frame timing continues updating while the visible draw count remains non-zero.

## Traversal

Expected result:

- `W A S D` keeps the player grounded across the district and corridor.
- `Shift` increases movement speed.
- Collision still blocks major buildings, medians, and the corridor backstop.
