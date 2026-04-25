# Cycle 45 Smoke Test

Verify that the Canberra demo now behaves as a cycle `45` alternate-route promotion-audit pass: the active Woden-to-Belconnen route remains the only bound playable route, while the staged alternate route reports a promotion audit that confirms the live binding is unchanged.

## Boot Shell

1. Build and launch `MilsimPonyGame`.
2. Start from the briefing shell.
3. Confirm the scene title reads `Canberra Alternate Route Audit Validation`.
4. Confirm the HUD title reads `Cycle 45 Alternate Route Promotion Audit`.
5. Confirm route details include:
   - `Route Promotion: promotion readiness staged; active route still locked`
   - `Route Audit: promotion audit passed for review; live binding unchanged`

## Live Route

1. Start the rehearsal and move through the Woden-to-Belconnen route.
2. Confirm the active route remains `Canberra Combat-Lane Rehearsal`.
3. Confirm route details report `alternate route promotion audit staged`.
4. Confirm the staged alternate route remains preview-only and does not replace the active checkpoint order.
5. Restart from a checkpoint and confirm the restart still returns to the active route instead of the staged alternate.

## Overhead Map

1. Open the overhead map.
2. Confirm the active route line still names the primary route and selected alternate.
3. Confirm the map footer includes:
   - `Route Promotion:` with the promotion-readiness rule.
   - `Route Audit:` with the active-binding audit rule.
4. Confirm the Woden-to-Belconnen route polyline and current checkpoint remain visually unchanged.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `45` label and `promotion audit passed for review; live binding unchanged`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `45` alternate-route promotion-audit build.
