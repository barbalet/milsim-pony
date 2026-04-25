# Cycle 93 Smoke Test - Scope Optics And Concealment Polish

Verify that the Canberra demo now behaves as a cycle `93` scope-and-concealment pass: the existing route, map, collision preview, restore execution, and session audio remain intact while live scope calibration and vegetation concealment/traversal feedback are visible enough to support route tuning.

## Launch And Identity

- Launch the app.
- Confirm the briefing shell identifies `Canberra Scope Optics And Concealment Polish`.
- Confirm the overlay still reports guarded restore lines including `Restore Execution Design:`, `Restore Safety Checks:`, and `Session Audio:`.

## Scope Calibration

- Start the route and raise the 4x scope at a contact or skyline marker.
- Confirm the scope overlay still shows mil hold, parallax, recoil, and shot timing without covering the central reticle.
- Confirm the mission overlay reports `Scope Calibration:` with range, drop, mil hold, parallax, edge stability, and breath state.
- Hold `E` while scoped and confirm the calibration line changes from breath drift toward held-breath state.
- Fire once at a watcher or terrain lane and confirm `Scope Calibration:` and `Shot Timing:` continue updating after recoil.

## Vegetation Concealment And Traversal

- Move through the West Basin/Yarralumla or Black Mountain vegetation-heavy leg.
- Confirm the mission overlay reports `Vegetation Concealment:` with screening state, traversal state, observer masking/seeing state, and current sector.
- Walk, stop, and sprint in the vegetated leg; confirm traversal changes between settled, soft rustle, and fast rustle states.
- Let an observer gain line of sight and confirm the concealment line reports the screen breaking when the player is seen.

## Route And Map Regression

- Open the overhead map and confirm route candidates, threat rings, named roads, and collision blocker footprints still draw.
- Arm `East Basin To Belconnen Probe` from briefing and confirm alternate-route live binding still works only from briefing or restart boundary.
- Confirm the third route remains preview-only.

## Restore And Audio Regression

- Review then execute a valid persisted restore target if one exists.
- Confirm the restore still lands at the stored checkpoint progress and consumes the restore token.
- Confirm `Session Audio:` still reports world, movement, and scope mix state after fresh start, retry, and restore.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
