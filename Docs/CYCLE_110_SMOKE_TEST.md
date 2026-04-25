# Cycle 110 Smoke Test - Firing Feedback Closeout

Verify that the Canberra demo behaves as a cycle `110` firing-feedback pass while preserving the cycle `99` through `109` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 110 Firing Feedback Closeout`.
- Confirm the release display reports `v1.10.0 (110)`.

## Scoped Rifle Feedback

- Raise the 4x scope and fire once.
- Confirm the scope shows a short visible muzzle flash pulse near the lower aperture.
- Confirm the reticle visibly kicks and recovers instead of staying static.
- Confirm `Muzzle Feedback:` no longer reports a placeholder flash.
- Confirm `Shot Feedback:` reports hit confirmation, blocker strike, ground impact, or clear miss with recoil percentage and distance.
- Confirm `Shot Timing:` still reports crack-thump timing and resolves after the impact window.

## Regression

- Preserve Cycle 109 authored audio mix and `Audio Mix:` readouts.
- Preserve Cycle 108 render graph readouts and pass labels.
- Preserve Cycle 107 SSR/IBL reflection prototype.
- Preserve Cycle 106 SDF UI readability.
- Preserve capture and package validation paths.
