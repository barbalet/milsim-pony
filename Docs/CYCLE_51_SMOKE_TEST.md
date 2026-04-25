# Cycle 51 Smoke Test

Verify that the Canberra demo now behaves as a cycle `51` collision-authoring readiness pass: the active Woden-to-Belconnen route remains the only bound playable route, while the build reports the blocker inventory needed before alternate-route collision editing.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Collision Authoring Readiness Validation`.
4. Confirm the HUD title reads `Cycle 51 Collision Authoring Readiness`.
5. Confirm route details include `Collision Authoring:` with the blocker-inventory readiness rule.

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Confirm route details still report `Route Preflight: live-switch preflight staged; active binding unchanged`.
4. Confirm `Collision Authoring:` reports runtime blocker counts without changing checkpoint order.
5. Restart from a checkpoint and confirm the restart still returns to the active route.

## Overhead Map

1. Open the overhead map.
2. Confirm the map footer includes `Collision Authoring:` after the route handoff line.
3. Confirm the collision-authoring line includes the blocker scope for graybox blocker volumes and authored sector collision volumes.
4. Confirm the Woden-to-Belconnen route polyline and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `51` label and `collisionAuthoring` block.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `51` collision-authoring readiness build.
