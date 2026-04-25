# Cycle 114 Smoke Test - Scope Optics Closeout

Verify that the Canberra demo behaves as a cycle `114` scope optics closeout while preserving the cycle `99` through `113` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 114 Scope Optics Closeout`.
- Confirm the release display reports `v1.14.0 (114)`.

## Scope Optics

- Raise the 4x scope and confirm the aperture shows subtle lens dirt specks and red/cyan edge aberration rings.
- Confirm the reticle still has usable mil-dot ticks and now labels the `1.0 mil` spacing near the center stadia.
- Confirm the scope overlay reports parallax compensation and the `Scope Calibration:` line includes mil-dot spacing plus compensated parallax.
- Fire while scoped and confirm muzzle flash, recoil offset, bloom recovery, and shot feedback still remain readable through the optic.
- Hold steady aim and confirm parallax/bloom reporting improves without hiding the calibrated mil-dot cues.

## Regression

- Preserve Cycle 113 route selection across the primary route and both alternates.
- Preserve Cycle 112 district texture coverage and `Black Mountain Materials:` / `West Basin Materials:` readouts.
- Preserve Cycle 111 patrol-pair movement and `Patrol Pairs:` readouts.
- Preserve Cycle 110 scoped firing feedback and `Shot Feedback:` readouts.
- Preserve capture and package validation paths.
