# Cycle 95 Smoke Test - Distant LOD And Water Reflection Probe

Verify that the Canberra demo now behaves as a cycle `95` LOD/reflection-evidence pass: current full-mesh rendering and material-driven water remain the shipping path, while key landmark impostor candidates and water reflection-probe targets are visible enough to guide the later renderer implementation.

## Launch And Identity

- Launch the app.
- Confirm the briefing shell identifies `Canberra Distant LOD And Water Reflection Probe`.
- Confirm the overlay still reports `Shadow Profile:`, `CSM Profile:`, `Scope Calibration:`, `Vegetation Concealment:`, `Session Audio:`, and guarded restore lines.

## LOD And Reflection Readouts

- Start the route and wait for the renderer to submit frames.
- Confirm the mission overlay reports `Distant LOD:` with landmark target count, impostor start distance, target names, and scoped stability rule.
- Confirm the mission overlay reports `Water Reflection:` with probe target count, West Basin/lake targets, probe approach, and SSR deferral status.
- Confirm the mission overlay reports `LOD Reflection:` combining the LOD metadata, reflection metadata, and live frame timing.

## Scoped Landmark Stability

- Raise the 4x scope at Woden, West Basin, Black Mountain, or Belconnen sightlines.
- Confirm `Scope Calibration:`, `CSM Profile:`, and `LOD Reflection:` remain visible while scoped.
- Confirm the readout still indicates full meshes remain active until impostor skyline-pop review passes.

## Map Regression

- Open the overhead map.
- Confirm the map footer includes `Distant LOD:` and `Water Reflection:` after the surface-fidelity lines.
- Confirm route candidates, threat rings, named roads, collision blocker footprints, active checkpoint markers, and shadow profile footer still draw.

## Water Reflection Evidence

- Move to the West Basin or lake-facing route segment.
- Confirm `Water Reflection:` lists the water or shoreline probe targets.
- Confirm `West Basin Materials:` and `Environmental Motion:` still report water motion, shoreline ripple, and vegetation response.

## Data Regression

- Confirm JSON scene data loads without fallback.
- Confirm the app still builds in Debug with code signing disabled.
