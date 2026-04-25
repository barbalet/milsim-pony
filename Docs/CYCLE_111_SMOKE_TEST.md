# Cycle 111 Smoke Test - Group NPC Behavior Closeout

Verify that the Canberra demo behaves as a cycle `111` group-NPC behavior pass while preserving the cycle `99` through `110` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 111 Group NPC Behavior Closeout`.
- Confirm the release display reports `v1.11.0 (111)`.

## Patrol Pair Behavior

- Let the route idle near the first paired observer group.
- Confirm `Patrol Pairs:` reports authored pairs, active members, moving count, route, roles, spacing, and live sweep offset.
- Confirm the overhead map threat markers drift from their authored anchors while the pair is idle.
- Alert an observer and confirm the pair halts scan/patrol movement while alert memory is active.
- Let alert memory expire or restart from a checkpoint and confirm the patrol resumes without losing the authored formation route.

## Regression

- Preserve Cycle 110 scoped firing feedback and `Shot Feedback:` readouts.
- Preserve Cycle 109 authored audio mix and `Audio Mix:` readouts.
- Preserve Cycle 108 render graph readouts and pass labels.
- Preserve Cycle 107 SSR/IBL reflection prototype.
- Preserve capture and package validation paths.
