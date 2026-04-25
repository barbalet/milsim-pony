# Cycle 98 Smoke Test - Time-Of-Day And Lighting Architecture Decision

Verify that the Canberra demo now behaves as a cycle `98` lighting-architecture pass: the route remains stable, fixed daylight stays the shipping path, and clustered lighting/render-graph modernization is gated by measured prerequisites.

## Launch And Identity

- Launch the build and confirm the briefing shell identifies `Canberra Lighting Architecture Decision`.
- Confirm the release display reports `v0.98.0 (98)`.

## Lighting Readouts

- Confirm the mission overlay reports `Lighting Plan:` with the static daylight scenario, time-of-day label, single-sun policy, clustered-lighting decision, render-graph decision, measured prerequisites, smoke doc, and frame timing.
- Confirm the overhead-map footer includes `Lighting Plan:` after `Tester Delivery:`.
- Confirm `CSM Profile:`, `LOD Reflection:`, `Packaging:`, and `Tester Delivery:` remain visible.

## Scenario Stability

- Raise the scope at skyline-heavy stops and confirm the lighting plan does not imply dynamic time-of-day animation.
- Confirm the route still uses authored sky, sun, atmosphere, shadow, and postprocess data rather than a procedural fallback.
- Confirm skyline readability remains stable while panning over Woden, Civic, Black Mountain, and Belconnen markers.

## Architecture Note

- Open `Docs/LIGHTING_ARCHITECTURE_DECISION.md`.
- Confirm it records the single-sun daylight decision, clustered/Forward+ deferral, render-graph deferral, measured prerequisites, and next renderer gate.

## Packaging Regression

From the repository root, run:

```bash
Tools/package_release.sh --validate-only
Tools/package_release.sh --check-distribution
```

- Confirm the version policy is `0.98.0` with build `98`.
- Confirm release docs include `Docs/CYCLE_98_SMOKE_TEST.md`, `Docs/LIGHTING_ARCHITECTURE_DECISION.md`, `Docs/TESTER_DISTRIBUTION_PIPELINE.md`, and `Docs/DEVELOPMENT_BACKLOG.md`.
