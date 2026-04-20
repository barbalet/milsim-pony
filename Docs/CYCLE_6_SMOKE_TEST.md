# Cycle 6 Smoke Test

## Goal

Verify that the Canberra slice now reads more clearly on first launch through a cycle `6` credibility pass: the overlay briefs the current route leg, traversal tuning is exposed in the HUD, and atmospheric fog helps the corridor silhouette and signposting read at a distance.

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

- The app launches to the `Cycle 6 Credibility Pass` overlay.
- The overlay includes a `Briefing:` section in addition to route, evasion, and streaming data.
- The scene summary now reports traversal tuning alongside the existing district, route, and threat counts.

## Briefing And Guidance

Expected result:

- The `Briefing:` summary reports the current route leg and target checkpoint.
- The briefing details include a leg description, a cardinal heading, and a pace recommendation.
- Near the cross-street midpoint, the overlay can reference the added `Cut To Service Lane` signpost or nearby cover.
- After failure, the briefing changes to a break-contact/reset prompt rather than continuing to show an advance instruction.

## Atmosphere And Readability

Expected result:

- Distant geometry fades into a light Canberra haze instead of holding the same contrast as nearby geometry.
- The sky gradient appears slightly warmer and brighter near the horizon.
- Route beacons, signposts, and nearby cover are easier to visually separate from the background corridor.

## Traversal Tuning

Expected result:

- The `Move Speed:` HUD line includes configured walk, sprint, and look values.
- Normal traversal feels slightly faster than cycle `5`, and sprinting opens clearer gaps between cover positions.
- Mouse look remains smooth after the tuning pass and still clamps pitch correctly.

## Regression Check

Expected result:

- `W A S D`, mouse look, and `Shift` still work for normal traversal.
- Detection, fail, retry, and checkpoint progress still behave as in cycle `5`.
- Completing the final checkpoint still reaches the escape corridor exit and allows a clean restart with `R`.
