# Cycle 94 Smoke Test - CSM And Formal Renderer Profile

Verify that the Canberra demo now behaves as a cycle `94` CSM-readiness and renderer-profile pass: the current single sun shadow map remains the shipping path, while authored cascade targets, scoped coverage, bias settings, and live frame/core/world profiling are exposed before any multi-texture cascade implementation.

## Launch And Identity

- Launch the app.
- Confirm the briefing shell identifies `Canberra CSM And Renderer Profile Validation`.
- Confirm the overlay still reports `Scope Calibration:`, `Vegetation Concealment:`, `Session Audio:`, `Restore Execution Design:`, and `Restore Safety Checks:`.

## Shadow Profile Readout

- Start the route and wait for the renderer to submit frames.
- Confirm the mission overlay reports `Shadow Profile:` with the CSM readiness status and planned cascade summary.
- Confirm the mission overlay reports `CSM Profile:` with the shadow profile, frame timing, sector count, and blocker count.
- Raise the 4x scope at a skyline-heavy stop and confirm the CSM profile continues to report scoped coverage rather than losing the profiling line.

## Map Regression

- Open the overhead map.
- Confirm the map footer includes `Shadow Profile:` after the environmental-motion line.
- Confirm route candidates, threat rings, named roads, collision blocker footprints, and active checkpoint markers still draw.

## Route And Renderer Regression

- Traverse from Woden toward the West Basin or Black Mountain leg.
- Confirm `Profile Baseline:` and `CSM Profile:` update without hiding weapon, scope, LOS, or concealment telemetry.
- Fire once while scoped and confirm `Scope Calibration:`, `Shot Timing:`, and `CSM Profile:` remain visible.
- Restart from a checkpoint and confirm the shadow profile lines return after recovery.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
