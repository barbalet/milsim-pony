# Cycle 85 Smoke Test - Alternate Route Live Binding First Pass

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra Alternate Route Live Binding Validation`.
- Confirm the title shell shows an `Arm Alternate Route:` action for `East Basin To Belconnen Probe`.

## Primary Route Default

- Start the demo without arming the alternate route.
- Confirm the HUD reports `Alternate Live Binding: primary route active / alternate staged`.
- Confirm the active route line still names `Canberra Combat-Lane Rehearsal` and the first checkpoint remains the Woden start sequence.

## Alternate Route Binding

- Return to briefing, choose `Arm Alternate Route: East Basin To Belconnen Probe`, then start the demo.
- Confirm the HUD reports `Alternate Live Binding: active East Basin To Belconnen Probe / checkpoints rebound`.
- Open the map and confirm the active route is `East Basin To Belconnen Probe`, with the alternate checkpoint count and route footer matching the rebound route.

## Guardrails

- Confirm the alternate arming action is only available from the title briefing shell.
- Confirm arming is consumed after the fresh-run boundary so another route change does not happen mid-run.
- Restart or return to briefing and confirm the primary route remains available as fallback metadata.

## Regression

- Confirm `World Audio:`, `Scan Halt Resume:`, `LOS Debug:`, and `Patrol Pairs:` still update on the active route.
- Fire the rifle and confirm muzzle feedback, shot timing, and profiling baseline still update.
- Complete or retry a checkpoint and confirm checkpoint recovery uses the currently active route sequence.
