# Cycle 92 Smoke Test - Manual Restore Execution And Session Audio Polish

Verify that the Canberra demo now behaves as a cycle `92` guarded manual-restore pass: a valid persisted review card can restore to its checkpoint only after the target is reviewed and the explicit restore execution control is used, while session audio state reports fresh-start, retry, restore, and live-world mix transitions.

## Launch And Restore Gate

- Launch the app.
- Confirm the briefing shell identifies `Canberra Manual Restore Execution Validation`.
- Confirm the title shell shows `Review Restore Target:` when a valid persisted review card exists.
- Confirm `Execute Restore:` remains disabled until the restore target has been reviewed.
- Use `Review Restore Target:` and confirm `Execute Restore:` becomes available only for the reviewed target.

## Guarded Execution

- Use `Execute Restore:` after reviewing a valid target.
- Confirm the run enters live play at the stored checkpoint progress rather than the fresh Woden start.
- Confirm `Restore Boundary Reset:` reports that the restore token was consumed.
- Confirm `Restore Execution Gate:` and `Restore Safety Checks:` still report the identity, target, freshness, and intent model.
- Confirm completed, stale, mismatched, or target-missing review cards still block execution and fall back to fresh-start behavior.

## Session Audio

- Confirm the overlay reports `Session Audio:` with world, movement, and scope mix state.
- Start a fresh run and confirm the session-audio line reports fresh-run basin-bed arming.
- Retry from a checkpoint and confirm the session-audio line reports checkpoint retry mix reset.
- Execute a guarded restore and confirm the session-audio line reports manual restore cue plus basin bed.

## Route And Map Regression

- Open the overhead map and confirm route candidates, threat rings, named roads, and collision blocker footprints still draw.
- Arm `East Basin To Belconnen Probe` from briefing and confirm alternate-route live binding still works only from briefing or restart boundary.
- Confirm the third route remains preview-only.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
