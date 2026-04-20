# Cycle 3 Smoke Test

## Goal

Verify that the Parliament House district graybox is traversable on foot with grounded movement, collision, road and terrain content, and sector-based chunk activation.

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

- The app launches to the `Cycle 3 District Slice` overlay.
- The overlay reports `Parliament House District Graybox`.
- The scene shows a blue sky backdrop plus sloped terrain and dark road/structure masses around the spawn.

## Traversal

Expected result:

- The player spawns at `State Circle South Verge`.
- `W A S D` moves the camera across the district while keeping the camera grounded to the terrain and roads.
- `Shift` increases move speed and updates the overlay sprint state.
- The player cannot pass through major building masses, median blockers, or outer boundary blockers.
- Resetting the debug state returns the player to the configured spawn.

## Streaming

Expected result:

- The overlay shows a `Chunks:` line with active versus total sectors.
- The overlay shows `Active:` and `Current Sector:` lines that change as the player moves through the district.
- Frame timing continues updating while streamed drawables remain non-zero.

## HUD Checks

Expected result:

- The overlay shows `Ground:` with a grounded state and active-sector count.
- The overlay scene summary reflects terrain, roads, and structures rather than only procedural bootstrap geometry.
