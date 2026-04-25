# Cycle 91 Smoke Test - Manual Restore Execution Design

Verify that the Canberra demo now behaves as a cycle `91` manual-restore execution-design pass: persisted review cards can be inspected through a concrete restore UI and logic contract, but checkpoint restore execution remains disabled until the Cycle 92 gate implementation.

## Launch And Restore Contract

- Launch the app.
- Confirm the briefing shell identifies `Canberra Manual Restore Execution Design Validation`.
- Confirm the title shell still offers `Start Demo` and the restore target review button when a valid persisted review card exists.
- Confirm the title shell also shows an `Execute Restore:` control when a valid target exists, and that the control is disabled.
- Confirm starting the demo still begins a fresh run, even after reviewing a restore target.

## Overlay Safety Lines

- Inspect the mission overlay.
- Confirm it reports `Restore Execution Design:` with the target checkpoint or a clear blocked reason.
- Confirm it reports `Restore Safety Checks:` with identity, target, freshness, and intent-token states.
- Confirm `Restore Execution Gate:` remains closed and does not claim checkpoint restore is live.

## Route And Map Regression

- Open the overhead map and confirm route candidates, threat rings, named roads, and collision blocker footprints still draw.
- Start the primary route and clear at least one checkpoint.
- Return to briefing or restart and confirm restore review state clears at boundaries instead of executing a checkpoint restore.
- Arm `East Basin To Belconnen Probe` and confirm alternate-route live binding still works only from briefing or restart boundary.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
