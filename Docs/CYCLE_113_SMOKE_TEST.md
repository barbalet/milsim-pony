# Cycle 113 Smoke Test - Multi-Route Playability

Verify that the Canberra demo behaves as a cycle `113` multi-route playability build while preserving the cycle `99` through `112` REVIEW recovery work.

## Build And Launch

- Build the `MilsimPonyGame` scheme.
- Confirm the HUD title reads `Cycle 113 Multi-Route Playability`.
- Confirm the release display reports `v1.13.0 (113)`.

## Route Selection

- From the briefing shell, confirm the route selector button is available and reports the currently selected route.
- Cycle the selector through the primary Woden-to-Belconnen route, `East Basin To Belconnen Probe`, and `West Basin To Ginninderra Shore Thread`.
- Start the demo after selecting each route and confirm `Route Selection:` reports that the selected route is active and checkpoints were rebound.
- Open the overhead map on each run and confirm the active route path, checkpoint labels, and threat lane geometry match the selected route rather than the previous run.
- Restart a live run and confirm the same active route is rebound instead of silently falling back to the primary route.
- Return to briefing and confirm a fresh primary-route start is still available.

## Regression

- Preserve Cycle 112 district texture coverage and `Black Mountain Materials:` / `West Basin Materials:` readouts.
- Preserve Cycle 111 patrol-pair movement and `Patrol Pairs:` readouts.
- Preserve Cycle 110 scoped firing feedback and `Shot Feedback:` readouts.
- Preserve Cycle 109 authored audio mix and `Audio Mix:` readouts.
- Preserve capture and package validation paths.
