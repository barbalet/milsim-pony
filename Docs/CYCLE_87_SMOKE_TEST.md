# Cycle 87 Smoke Test - Black Mountain Texture Closeout

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra Black Mountain Texture Closeout Validation`.
- Confirm the route/map details include `Black Mountain Materials:`.

## Primary Route Material Pass

- Start the primary route and proceed to `Black Mountain Scope Perch`.
- Raise the scope and frame Telstra Tower, Black Mountain slopes, and the Bruce/AIS saddle together.
- Confirm the route details report `Black Mountain Materials: Telstra/Bruce source-backed assignments`.
- Confirm the `Surface Fidelity:` line reports the Black Mountain/Telstra/Bruce material closeout.

## Map And Capture Notes

- Open the map at the Black Mountain stop.
- Confirm the map footer includes `Black Mountain Materials:` with `Canberra Texture Library`.
- Confirm the Black Mountain comparison capture note asks for Telstra concrete, Black Mountain dry-grass slopes, and Bruce/AIS facade breakup in one frame.
- Confirm the active route path, `Map Accuracy:`, threat rings, and route footer still match the currently active route.

## Alternate Route Regression

- Return to briefing, arm `East Basin To Belconnen Probe`, and start the alternate route.
- Advance to the Black Mountain segment and confirm the same material closeout line remains visible.
- Confirm the alternate route remains live-bound and the material closeout does not alter checkpoint order, collision, observer behavior, or route recovery.

## Regression

- Confirm `World Audio:`, `Scan Halt Resume:`, `LOS Debug:`, `Patrol Pairs:`, scoped rifle feedback, and `Map Accuracy:` still update during the Black Mountain pass.
- Confirm the texture audit in `MilsimPonyGame/Assets/Textures/README.md` documents the source-backed Black Mountain/Telstra/Bruce assignments.
