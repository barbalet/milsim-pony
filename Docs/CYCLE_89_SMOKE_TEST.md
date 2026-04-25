# Cycle 89 Smoke Test - Third Rehearsal Route Authoring

Verify that the Canberra demo now behaves as a cycle `89` third-route authoring pass: the selected `East Basin To Belconnen Probe` remains the live-bindable alternate, while `West Basin To Ginninderra Shore Thread` is present as a second alternate candidate with map preview, readiness metadata, and route-specific threat geometry.

## Launch And Route Shell

- Launch the app.
- Confirm the briefing shell identifies `Canberra Third Rehearsal Route Authoring Validation`.
- Confirm route details report `Alternate Routes: 2 candidates`.
- Confirm route details still list the selected `East Basin To Belconnen Probe` as live binding ready from briefing.
- Confirm route details also list `West Basin To Ginninderra Shore Thread` as a `third-route-authoring` preview.

## Map Preview

- Open the overhead map from the briefing shell.
- Confirm the active route path still draws as the Woden-to-Belconnen baseline.
- Confirm two alternate preview paths draw: the East Basin-to-Belconnen candidate and the West Basin-to-Ginninderra shore thread.
- Confirm the map footer reports `Alt Preview: 2 candidates` and includes the next authored route summary.

## Threat Geometry

- Inspect the West Basin and Ginninderra map areas.
- Confirm `West Basin Shore Thread Watch` and `Ginninderra Shore Thread Watch` appear as threat rings/cones.
- Confirm the map threat count increases without hiding the existing Woden, East Basin, Civic, Black Mountain, Belconnen, and Ginninderra watcher coverage.

## Live-Binding Regression

- Return to briefing, arm `East Basin To Belconnen Probe`, and start the alternate route.
- Confirm the live checkpoint sequence still binds only the selected East Basin route.
- Confirm the third route remains preview-only until future multi-candidate route selection is implemented.

## Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
