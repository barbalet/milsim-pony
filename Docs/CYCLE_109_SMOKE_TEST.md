# Cycle 109 Smoke Test - Authored Audio Mix Closeout

Verify that the Canberra demo behaves as a cycle `109` authored audio mix pass while preserving the cycle `99` through `108` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 109 Authored Audio Mix Closeout`.
- Confirm the release display reports `v1.9.0 (109)`.

## Audio Mix

- Start the live route and confirm `Session Audio:` reports ambience, movement, and scope cue state.
- Confirm `Audio Mix:` reports scene-authored category gains for ambience, movement, scope, weapon, and observer cues.
- Open Settings and adjust `Audio Master`; confirm the setting persists in the overlay and does not affect look/HUD controls.
- Walk, sprint, raise/lower scope, fire, and trigger observer pressure; confirm each cue class remains audible without masking the others.

## Regression

- Preserve Cycle 108 render graph readouts and pass labels.
- Preserve Cycle 107 SSR/IBL reflection prototype.
- Preserve Cycle 106 SDF UI readability.
- Preserve capture and package validation paths.
