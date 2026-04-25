# Lighting Architecture Decision

Cycle `98` keeps the renderer on a fixed Canberra daylight scenario and records the gates that must be measured before larger lighting architecture work begins.

## Decision

The shipping path remains a data-authored single-sun daylight model:

- `sky`, `sun`, `atmosphere`, `shadow`, and `postProcess` stay scene-authored.
- The current fixed review daylight is the minimal time-of-day scenario.
- Clustered or Forward+ lighting is deferred until the route has enough dynamic light sources to justify light-list building.
- A render graph is deferred until CSM, postprocess, water reflections, capture, and future lighting passes need explicit dependency scheduling.

## Current Scenario

- Scenario: `Canberra fixed daylight review`
- Time of day: `13:40 clear late-summer review light`
- Sun policy: single authored sun drives sky, shadow, terrain, and material lighting.
- Atmosphere policy: authored fog, haze, exposure, and sky colors remain the scenario controls.

## Measured Prerequisites

Before clustered lighting or render-graph work starts, collect:

- Frame timing with the current scene, route, map, and scope readouts active.
- CSM profile evidence for cascade split targets, coverage, and bias.
- LOD/reflection evidence for skyline shimmer and water/reflection stability.
- Dynamic light count proof from real gameplay needs rather than speculative renderer design.
- Pass-count pressure from CSM, postprocess, capture, water reflection, and future lighting work.

## Next Renderer Gate

The next lighting cycle should only promote architecture if one of these becomes true:

- Dynamic source count exceeds the single-sun plus diagnostic-marker model.
- Render pass ordering becomes difficult to audit in `GameRenderer`.
- Time-of-day needs multiple authored scenarios rather than one fixed review daylight preset.
- Scoped skyline readability needs lighting changes that cannot be solved with current data-authored sky, sun, fog, haze, and exposure controls.
