# Canberra Basin And Sniper Plan

## Review Correction

The current demo proves the app shell, renderer, and a small Canberra-adjacent route, but it does not yet satisfy the project goal of showing Canberra itself at meaningful scale. The next five calibrated cycles must prioritize a basin-scale Canberra demo that visibly includes Lake Burley Griffin and the broader landscape from Woden to Belconnen.

## Priority Outcomes

- Render a coherent Canberra basin view instead of only a tight Parliament corridor.
- Show Lake Burley Griffin as a readable world landmark, not a deferred placeholder.
- Extend visible terrain and landmark coverage south to Woden and north-west to Belconnen.
- Raise terrain, road, landmark, and collision resolution enough that distant observation is useful.
- Make the first usable weapon a sniper rifle with 4x magnification.

## Cycle Timing Reset

- Treat cycles `10` to `14` as Canberra coverage gates, not one-week sprints.
- Budget at least two weeks per cycle for reference gathering, world-data authoring, and in-engine review, with a third integration week available whenever new imports or tile rebuilds are required.
- Do not mark a cycle complete unless the demo opens from a recognisable Canberra survey location and the build shows net-new Woden-to-Belconnen readability.
- Engine, rendering, and gameplay work only count when they unlock or verify the Canberra model rather than distracting from it.

## World Coverage Target

- South anchor: Woden Valley and its surrounding ridgelines.
- Central anchor: Parliament House, Lake Burley Griffin, and the Parliamentary Triangle.
- North-west anchor: Belconnen basin and its approach landscape.
- Supporting skyline landmarks: Black Mountain / Telstra Tower silhouette, basin ridges, major arterial corridors, and distinct district massing.

## Resolution Strategy

- Use hierarchical world data instead of one flat scene scale.
- Keep basin-wide terrain and water coverage always available at macro resolution.
- Stream higher-resolution terrain, roads, buildings, vegetation, and collision around authored viewpoints, travel lanes, and sniper firing lines.
- Preserve long-distance silhouette readability even when fine detail is not fully resident.

## Sniper Rifle Requirements

- Weapon: sniper rifle as the first usable firearm.
- Optic: 4x magnification with a dedicated scoped render path.
- World support: long-range landmark readability, stable distant LODs, accurate collision queries, and authored firing positions.
- Gameplay support: equip, aim, zoom, fire, reload, impact confirmation, and target validation at long range.

## Cycle Breakdown

### Cycle 10: Basin Data And Streaming Reset

- Lock expanded Canberra extents from Woden to Belconnen.
- Replace corridor-first assumptions with basin-first world packaging and sector rules.
- Import first-pass macro terrain, lake footprint, and district coverage data.
- Define sniper use cases, firing distances, target sizes, and required world resolution bands.

Exit gate:

- The app can load a basin-scale Canberra preview with Lake Burley Griffin footprint and visible south/north-west district extents.

### Cycle 11: Macro Canberra Readability

- Add basin-wide terrain, water, skyline, and haze presentation.
- Establish landmark silhouettes and district massing that make Canberra recognizable at large scale.
- Calibrate camera, clipping, fog, and scale against long sightlines instead of only close traversal.
- Keep the Parliament anchor slice runnable while the wider basin comes online.

Exit gate:

- From an authored viewpoint, the player can read the lake and the broader landscape toward both Woden and Belconnen.

### Cycle 12: High-Resolution Terrain And Scope Foundation

- Stream denser terrain, road, and collision tiles around the central basin and planned sniper lanes.
- Add a 4x scope camera, reticle, and magnified render path.
- Stabilize distant LOD transitions so zoomed views do not shimmer or collapse.
- Build the first sniper perches, sight tests, and landmark validation route.

Exit gate:

- The player can use a 4x scope to inspect distant Canberra landmarks with stable magnified rendering.

### Cycle 13: Sniper Rifle Usable Pass

- Add the first sniper rifle weapon flow: equip, aim, zoom, fire, reload, and hit feedback.
- Implement long-range query support for accurate target hits across basin-scale sightlines.
- Raise collision and landmark resolution around authored firing lanes and target zones.
- Add sniper validation targets and test routes across central Canberra viewpoints.

Exit gate:

- A sniper rifle can be used reliably against authored long-range targets in the Canberra basin demo.

### Cycle 14: Basin Demo Integration

- Close major world holes between Woden, the lake, and Belconnen.
- Tune streaming, memory, and far-field performance for the expanded map.
- Polish water, terrain, skyline, and landmark readability for review builds.
- Integrate traversal and sniper observation into one reviewable Canberra demo flow.

Exit gate:

- The review build demonstrates Lake Burley Griffin and the full Woden-to-Belconnen landscape with a usable 4x sniper rifle path.

## Sequencing Rules

- Do not prioritize another narrow route slice ahead of basin-scale coverage.
- Do not ship the sniper rifle before the map can support long-range observation at useful fidelity.
- Treat Lake Burley Griffin and the basin ridgelines as world anchors for scale and orientation.
- Every cycle from 10 to 14 must improve both macro Canberra readability and sniper viability.
