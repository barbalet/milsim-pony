# Cycle 8 Smoke Test

## Goal

Verify that the Canberra slice now behaves as a cycle `8` beta hardening pass: the app advertises the updated cycle label, large frame hitches no longer let the player tunnel through thin blockers, and thin occluders reliably break observer line of sight instead of leaking suspicion through geometry.

## Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyDerived/Build/Products/Debug/`.

## Core Regression Harness

Run:

```bash
clang -IMilsimPonyGame/Core MilsimPonyGame/Core/GameCore.c Tools/gamecore_cycle8_regression.c -o /tmp/gamecore_cycle8_regression
/tmp/gamecore_cycle8_regression
```

Expected result:

- The harness prints `movement_substeps_ok`.
- The harness prints `thin_occluder_ok`.
- The harness exits successfully after printing `cycle8_regression_ok`.

## Launch

Run:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

Expected result:

- The HUD title reads `Cycle 8 Beta Hardening`.
- The input card subtitle references traversal, stability hardening, and routed escape controls rather than the old cycle `7` copy.
- The title shell, pause shell, settings shell, fail shell, and completion shell still behave as in cycle `7`.

## Hitch And Collision Hardening

Expected result:

- Sprinting into corridor fences, hedges, or service-lane barriers no longer lets the player skip through them after a hitch, resize, or focus change.
- Restarting from checkpoints near the Deakin corridor keeps the player on the correct side of nearby blockers instead of respawning beyond them.
- Route progress and distance still advance normally during smooth play and no sudden multi-checkpoint jump occurs after a long frame stall.

## Occlusion And Detection Hardening

Expected result:

- Thin blockers such as the median planter, shelter mass, and service-lane barriers reliably break observer sight when they sit between the camera and an observer.
- Suspicion no longer rises while the player is fully hidden behind narrow cover that visually seals the line.
- Detection, failure, retry, and checkpoint progress still recover cleanly after cover is used to break contact.

## Regression Check

Expected result:

- `W A S D`, mouse look, and `Shift` still control traversal during live gameplay.
- Pause, resume, retry, restart, and return-to-briefing flows still freeze and resume the simulation correctly.
- Completing the route still reaches `Extraction Canopy` and reports run time, distance, and restart count without developer intervention.
