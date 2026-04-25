# Cycle 80 Smoke Test

## Scoped Rifle Presentation

Verify that the Canberra demo now behaves as a cycle `80` scoped-rifle presentation pass: the shell advertises the new cycle, the scope overlay has mil-dot marks, and scoped firing exposes holdover, parallax, recoil recovery, and crack-thump timing.

## Launch And Shell

1. Build and launch `MilsimPonyGame`.
2. Confirm the scene title reads `Canberra Scoped Rifle Presentation Validation`.
3. Confirm the HUD title reads `Cycle 80 Scoped Rifle Presentation`.
4. Confirm the title shell still carries the restore review lines and the cycle `79` weapon/profiling lines.
5. Start the demo and confirm the live overlay includes `Optic:` and `Shot Timing:` lines.

## Scope Overlay

1. Raise the 4x scope with `Space`.
2. Confirm the reticle still has the circular aperture, central dot, moving aim offset, and spread bloom.
3. Confirm three mil-dot marks appear on each side of the horizontal and vertical reticle axes.
4. Confirm the scope label panel shows status, instruction, `Optic: mil`, and `Shot Timing:` rows without covering the central reticle.

## Scoped Firing

1. Aim at a contact lane observer through the scope.
2. Confirm the status row names the predicted observer when the ballistic prediction intersects a target.
3. Fire once and confirm `Shot Timing:` reports crack timing, pending or resolved thump state, classification, and distance.
4. Confirm `Optic:` reports holdover, parallax percentage, and recoil percentage while the rifle cycles.
5. Wait for the rifle to settle and confirm recoil recovers while the mil and parallax readouts remain stable.

## Hit, Miss, And Audio

1. Fire at an observer and confirm hit confirmation still appears in the status line.
2. Fire at nearby ground or cover and confirm blocker, ground, or clear-miss classification remains readable.
3. Confirm the shot, delayed impact, hit-confirm, and dry-click cues still play.
4. Confirm `Muzzle Feedback:` and `Profile Baseline:` remain visible in the overlay.

## Regression Checks

1. Open and close the overhead map while scoped; confirm the scope overlay returns cleanly.
2. Pause, resume, restart route, and return to briefing; confirm scoped state and input focus recover.
3. Confirm restore review intent remains non-executable.
4. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `80` scoped-rifle presentation build.
5. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `80` label and combat-rehearsal summary.
