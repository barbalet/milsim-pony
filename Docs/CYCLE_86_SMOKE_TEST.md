# Cycle 86 Smoke Test - Route Breadth And Map Accuracy

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra Route Breadth And Map Accuracy Validation`.
- Confirm the title shell still shows an `Arm Alternate Route:` action for `East Basin To Belconnen Probe`.

## Primary Route Accuracy

- Start the demo without arming the alternate route.
- Confirm the HUD reports `Alternate Live Binding: primary route active / alternate staged`.
- Open the map and confirm `Map Accuracy:` names `Canberra Combat-Lane Rehearsal`.
- Confirm the route marker count, next checkpoint label, planned-distance footer, and threat-ring count agree with the primary route.

## Alternate Route Accuracy

- Return to briefing, choose `Arm Alternate Route: East Basin To Belconnen Probe`, then start the demo.
- Confirm the HUD reports `Alternate Live Binding: active East Basin To Belconnen Probe / checkpoints rebound`.
- Confirm route and briefing lines advance through the alternate checkpoint sequence, beginning at `East Basin Lookout`.
- Open the map and confirm `Map Accuracy:` names `East Basin To Belconnen Probe`, reports the alternate marker count, keeps threat rings visible, and uses the alternate planned-distance footer.

## Route Footer And Recovery

- Advance or retry a checkpoint on each route.
- Confirm `Next:`, `Route:`, briefing marker count, cleared route path, and the map footer all follow the currently active route.
- Confirm returning to briefing without re-arming resets the live route to the primary checkpoint sequence.

## Regression

- Confirm `World Audio:`, `Scan Halt Resume:`, `LOS Debug:`, `Patrol Pairs:`, and scoped rifle feedback still update during both route passes.
- Confirm alternate preview geometry remains visible as reference metadata while the active route path is the committed checkpoint sequence.
