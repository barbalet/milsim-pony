# Cycle 83 Smoke Test - Scan-Halt-Resume Behavior

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra Patrol Scan-Halt-Resume Validation`.
- Start the route and confirm the HUD still shows `Observer Feedback:`, `Patrol Pairs:`, `LOS Debug:`, `Scan State:`, and `Scan Halt Resume:`.

## Patrol Scan

- Begin at Woden and watch the observer yaw values in `Scan State:` change over time while no alert is active.
- Confirm patrol-pair observers report non-zero scan arcs and scan cycle phase through `Scan Halt Resume:`.
- Confirm static unpaired observers do not inflate the patrol scan counts.

## Halt And Relay Handoff

- Step into a paired observer cone until tracking begins.
- Confirm `Scan Halt Resume:` increments the halted count and the focus observer reports `halted`.
- Break direct sight but stay near the pair and confirm relay handoff can increment while alert memory remains active.
- Confirm `Observer Feedback:` and `LOS Debug:` still agree on relay and blocked sample counts.

## Resume

- Stay behind cover until alert memory clears.
- Confirm the halted count drops, resume count rises, and the focus observer reports `resuming`.
- Confirm the scan yaw starts sweeping again instead of staying locked to the last alert target.

## Regression

- Confirm checkpoint restart clears active alerts and returns patrol observers to scanning.
- Raise the 4x scope and confirm scope presentation, shot timing, muzzle feedback, and profiling baseline still update.
- Complete or retry a lane and confirm checkpoint recovery still functions after scan-halt-resume activity.
