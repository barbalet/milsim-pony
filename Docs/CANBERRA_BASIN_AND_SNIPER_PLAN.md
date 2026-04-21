# Canberra Basin Atlas And Sniper Plan

## Review Correction

The current demo proves the app shell, renderer, and a growing Canberra route, but it still needs a denser district atlas before it fully satisfies the project goal of showing Canberra itself at meaningful scale. The next six calibrated cycles must prioritize a basin-scale Canberra demo that visibly includes Lake Burley Griffin, the broader landscape from Woden to Belconnen, and a clearer district street network across the central basin.

## Priority Outcomes

- Render a coherent Canberra basin view instead of only a tight Parliament corridor.
- Show Lake Burley Griffin as a readable world landmark, not a deferred placeholder.
- Extend visible terrain and landmark coverage south to Woden and north-west to Belconnen.
- Expand the district street atlas so Civic, Barton-Russell, Woden, Black Mountain, and Belconnen each have readable road structure.
- Raise terrain, road, landmark, and collision resolution enough that distant observation is useful.
- Make the first usable weapon a sniper rifle with 4x magnification.

## Cycle Timing Reset

- Treat cycles `10` to `20` as Canberra coverage gates, not one-week sprints.
- Budget at least two weeks per cycle for reference gathering, world-data authoring, and in-engine review, with a third integration week available whenever new imports or tile rebuilds are required.
- Do not mark a cycle complete unless the demo opens from a recognisable Canberra survey location and the build shows net-new Woden-to-Belconnen readability.
- Engine, rendering, and gameplay work only count when they unlock or verify the Canberra model rather than distracting from it.

## World Coverage Target

- South anchor: Woden Valley and its surrounding ridgelines.
- Central anchor: Parliament House, Lake Burley Griffin, and the Parliamentary Triangle.
- North-west anchor: Belconnen basin and its approach landscape.
- Supporting skyline landmarks: Black Mountain / Telstra Tower silhouette, basin ridges, major arterial corridors, and distinct district massing.
- District atlas anchors: Civic, Barton-Russell, Mount Ainslie-Campbell, Woden Town Centre, Belconnen Town Centre, and west-basin connectors.

## Resolution Strategy

- Use hierarchical world data instead of one flat scene scale.
- Keep basin-wide terrain and water coverage always available at macro resolution.
- Stream higher-resolution terrain, roads, buildings, vegetation, and collision around authored viewpoints, travel lanes, and sniper firing lines.
- Preserve long-distance silhouette readability even when fine detail is not fully resident.

## Online Reference Stack

- Google Maps road-view captures define the street-atlas targets and should be refreshed whenever the district pass changes materially.
- Transport Canberra region maps provide a second source of district naming, corridor grouping, and Woden/Belconnen/Civic connective tissue.
- In-game screenshots belong in the same gallery so reviewers can compare target and result without reconstructing the route themselves.

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

### Cycle 15: Street Atlas Expansion Reset

- Reframe the demo as a Canberra street-atlas review instead of only a scope-validation pass.
- Expand the live package with more districts, including Civic, Barton-Russell, west-basin connectors, Woden Town Centre, and Belconnen Town Centre.
- Draw named roads directly into the overhead map and tune the overlay until the atlas reads at a glance.
- Capture the first reference gallery from Google Maps, official Canberra transport sources, and matching in-game scenes.

Exit gate:

- The game opens into a street-atlas review with visibly denser district coverage and a reference gallery on disk.

### Cycle 16: Woden And Inner-South Street Pass

- Raise local road, blocker, and landmark fidelity around Woden, State Circle, Deakin, and the west-basin approach.
- Improve overlapping district streaming rules so the atlas remains coherent when Woden and the inner south are both resident.
- Add or refresh source captures for Woden and the inner south whenever the road pass changes.
- Extend smoke coverage so the district pass can be regression-tested quickly.

Exit gate:

- Woden and the inner south read as connected Canberra districts with reviewable road structure.

### Cycle 17: Civic, Barton, Russell, And East-Basin Pass

- Densify the road network, landmark massing, and bridge approaches around Civic, City Hill, Barton, Russell, and Mount Ainslie.
- Improve central-basin route markers so reviewers can prove the atlas around the lake without developer narration.
- Tune district labels and map readability so the central package stops collapsing into one generic basin blob.
- Refresh the source gallery with corrected Google Maps captures for the central districts.

Exit gate:

- Central Canberra reads as a connected street network from the lake edge to the inner north and east.

### Cycle 18: Belconnen And Black Mountain Pass

- Raise local road, skyline, and cover fidelity around Black Mountain, Bruce, and Belconnen Town Centre.
- Improve far-field and local handoff so northern district targets remain readable through the scope.
- Add Belconnen-specific route markers and capture evidence for the district pass.
- Close the worst atlas gaps between Black Mountain and the Belconnen core.

Exit gate:

- Belconnen and Black Mountain read as distinct, named districts instead of only a generic north-west mass.

### Cycle 19: Cross-District Route Integration

- Merge the separate district passes into one longer survey route that proves the atlas from east basin to Belconnen.
- Tune restart, checkpoint, and HUD behavior for a longer multi-district session.
- Remove any district handoff that breaks orientation, road continuity, or lake-centric navigation.
- Capture a comparison set that shows the route against its source references.

Exit gate:

- One coherent route proves the atlas across the full Woden-to-Belconnen package.

### Cycle 20: Reference-Backed Review Pack

- Lock the first review pack that combines the street atlas, source captures, smoke tests, and open follow-up risks.
- Polish overlays, capture framing, and district naming so review builds can be compared quickly and repeatedly.
- Tie every reviewed district back to the future sniper and combat lanes that depend on it.
- Mark the atlas phase complete only when reviewers can compare source and result without extra explanation.

Exit gate:

- A reference-backed Canberra review pack is ready for the next combat-focused phase.

## Sequencing Rules

- Do not prioritize another narrow route slice ahead of basin-scale coverage.
- Do not ship the sniper rifle before the map can support long-range observation at useful fidelity.
- Treat Lake Burley Griffin and the basin ridgelines as world anchors for scale and orientation.
- Treat the online reference gallery as part of the asset pipeline rather than optional documentation.
- Every cycle from `10` to `20` must improve both Canberra readability and sniper viability, with cycles `15` to `20` also required to improve the street atlas.
