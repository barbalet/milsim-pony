# Cycle 82 Smoke Test - LOS Debug And Scan States

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra LOS Debug Scan-State Validation`.
- Start the route and confirm the HUD still shows route, pressure, observer feedback, patrol pairs, muzzle feedback, scope presentation, and profiling baseline lines.

## LOS Debug Overlay

- Confirm the HUD contains a `LOS Debug:` line.
- Verify it reports tracking, relay, blocked samples, off-axis samples, and open LOS counts.
- Move behind an authored cover screen and confirm the blocked sample count can rise while observer feedback continues to show masked lanes.
- Step back into a clean sightline and confirm open/tracking counts update without changing route progress.

## Scan State Overlay

- Confirm the HUD contains a `Scan State:` line.
- Verify the focus observer shows one of `tracking`, `relay scan`, `memory scan`, `blocked scan`, `off-axis sweep`, `open sweep`, or `idle sweep`.
- Confirm the same line reports scan arc, yaw, pitch, dot, and threshold values for route-author inspection.
- Trigger an alert, break line of sight, and confirm the focus can move through tracking, memory scan, and blocked scan states.

## Patrol Pair And Relay Regression

- Confirm `Patrol Pairs:` still reports authored pair count, focus group, active members, route ID, lead/wing roles, and spacing.
- Confirm a paired observer relay can raise the `LOS Debug:` relay count while the focus line can show `relay scan`.
- Confirm neutralizing or bypassing observers does not remove the overlay or crash the run.

## Weapon And Scope Regression

- Raise the 4x scope and confirm mil-dot ticks, holdover/parallax text, and crack-thump timing still render.
- Fire a shot and confirm muzzle feedback, recoil recovery, miss classification, and profiling baseline lines continue to update.
- Restart from the latest checkpoint and confirm the LOS debug lines repopulate after the route reloads.
