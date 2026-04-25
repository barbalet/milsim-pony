# Cycle 88 Smoke Test - West Basin Vegetation And Water Closeout

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra West Basin Vegetation And Water Closeout Validation`.
- Confirm route/map details include both `Black Mountain Materials:` and `West Basin Materials:`.

## West Basin Surface Pass

- Start the primary route and proceed to `West Basin Promenade Review`.
- Raise the scope and frame Commonwealth Avenue west, West Basin water, promenade hardscape, and the Yarralumla vegetation slope together.
- Confirm `West Basin Materials:` reports shoreline, water, and vegetation closeout.
- Confirm `Environmental Motion:` reports active vegetation response, shoreline ripple, and water response values.
- Confirm `Surface Fidelity:` reports the West Basin vegetation and water closeout.

## Map And Capture Notes

- Open the map at the West Basin stop.
- Confirm the map footer includes `West Basin Materials:` with water motion and vegetation response context.
- Confirm the West Basin comparison capture note asks for Commonwealth Avenue west, West Basin water motion, promenade hardscape, and Yarralumla vegetation response in one frame.
- Confirm `Map Accuracy:`, active route path, threat rings, and route footer still match the currently active route.

## Alternate Route Regression

- Return to briefing, arm `East Basin To Belconnen Probe`, and start the alternate route.
- Advance to the West Basin segment and confirm the same West Basin material and water closeout line remains visible.
- Confirm alternate live binding, checkpoint order, collision, observer behavior, route recovery, and `Black Mountain Materials:` remain intact.

## Regression

- Confirm `World Audio:`, `Scan Halt Resume:`, `LOS Debug:`, `Patrol Pairs:`, scoped rifle feedback, and `Map Accuracy:` still update during the West Basin pass.
- Confirm the texture audit in `MilsimPonyGame/Assets/Textures/README.md` documents the West Basin/Yarralumla and West Basin water assignments.
