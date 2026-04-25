# Cycle 49 Smoke Test

Verify that the Canberra demo now behaves as a cycle `49` alternate-route release-gate pass: the active Woden-to-Belconnen route remains the only bound playable route, while the staged alternate route reports that release is still blocked until future live-switch code exists.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Alternate Route Release Validation`.
4. Confirm the HUD title reads `Cycle 49 Alternate Route Release Gate`.
5. Confirm route details include:
   - `Route Confirmation: handoff confirmation staged; primary route remains bound`
   - `Route Release: release gate staged; live switch still disabled`

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Confirm route details report `alternate route release gate staged`.
4. Confirm the staged alternate route remains preview-only and does not replace the active checkpoint order.
5. Restart from a checkpoint and confirm the restart still returns to the active route unless an explicit future route switch is implemented.

## Overhead Map

1. Open the overhead map.
2. Confirm the active route line still names the primary route and selected alternate.
3. Confirm the map footer includes:
   - `Route Confirmation:` with the review-metadata confirmation rule.
   - `Route Release:` with the live-switch-disabled release rule.
   - `Route Handoff:` with the restart-safe handoff rule.
4. Confirm the Woden-to-Belconnen route polyline and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `49` label and `release gate staged; live switch still disabled`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `49` alternate-route release-gate build.
