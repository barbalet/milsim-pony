# Cycle 90 Smoke Test - Collision Authoring Preview Tool

Verify that the Canberra demo now behaves as a cycle `90` collision-authoring preview pass: the active and alternate rehearsal routes remain unchanged, while the overhead map visually exposes blocker footprints for graybox blocks and authored sector collision volumes.

## Launch And Route Shell

- Launch the app.
- Confirm the briefing shell identifies `Canberra Collision Authoring Preview Validation`.
- Confirm route details still report the selected `East Basin To Belconnen Probe` as live binding ready from briefing.
- Confirm `West Basin To Ginninderra Shore Thread` remains a preview-only third-route candidate.

## Collision Preview Map

- Open the overhead map from the briefing shell.
- Confirm the legend includes `Collision`.
- Confirm the map draws dashed blocker footprints over the same Canberra atlas used for roads, sectors, routes, threats, checkpoints, and the player marker.
- Confirm the footer reports `Collision Preview:` with total blocker footprints and authored/graybox counts.
- Confirm the collision preview does not hide named roads, route paths, active checkpoint markers, threat rings, or alternate-route previews.

## Runtime Regression

- Start the primary route and move through at least one checkpoint.
- Confirm the active Woden-to-Belconnen checkpoint sequence is unchanged.
- Restart from a checkpoint and confirm the collision-preview footer remains present after recovery.
- Arm `East Basin To Belconnen Probe` from briefing and confirm live binding still uses only the selected alternate route.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
