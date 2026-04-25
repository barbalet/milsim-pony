# Cycle 115 Smoke Test - Collision Authoring Workflow

## Purpose

Verify that Cycle 115 turns collision blocker preview into an actionable authoring workflow instead of a passive map overlay.

## Checks

1. Launch the app and stay on the briefing screen.
2. Confirm the title scene reports `Canberra Collision Authoring Workflow`.
3. Use `Collision Review:` from the briefing actions to cycle through blocker volumes.
4. Open the overhead map and confirm the selected blocker footprint is highlighted with a solid bright outline.
5. Confirm the map footer reports:
   - `Collision Preview:` with authored and graybox blocker counts.
   - `Collision Selection:` with blocker name, sector, source tier, dimensions, and area.
   - `Collision Validation:` with the configured minimum clearance.
   - `Collision Export:` with the owning source ID for sector JSON edits.
6. Start the demo after changing the selected blocker and confirm route binding still follows the selected briefing route only.
7. Run `Tools/package_release.sh --validate-only` and confirm the Cycle 115 release docs, version, and archive policy validate.
8. Run `Tools/capture_review.sh --validate-only` and confirm capture tooling defaults to Cycle 115.

## Expected Result

Collision authoring is now inspectable from the briefing and overhead map: designers can select each blocker footprint, see which sector and source tier owns it, read validation/export guidance, and carry the source ID into JSON edits without disturbing live route binding.
