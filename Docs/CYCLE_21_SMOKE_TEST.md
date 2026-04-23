# Cycle 21 Smoke Test

Verify that the Canberra demo now behaves as a cycle `21` combat-lane rehearsal: the shell advertises the new rehearsal framing, the live route carries observer pressure, and the overhead map exposes the next contact lane plus threat coverage without losing the street-atlas read.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the shell title reads `Canberra Combat-Lane Rehearsal`.
4. Confirm the HUD title reads `Cycle 21 Combat-Lane Rehearsal`.
5. Confirm the title shell lines mention the carried review pack plus the new combat rehearsal or exposure/recovery cues.

## Live Route

1. Start the run from `Woden Town Centre Staging`.
2. Reach `Woden Scope Perch`, `State Circle Transfer`, and `Civic Interchange Review`.
3. Confirm the route/briefing lines now surface a `Contact:` line and a `Cover:` line when a combat stop is active.
4. Confirm observer pressure can raise suspicion and still trigger the existing checkpoint fallback loop.
5. Confirm retrying from a failure returns to the latest checkpoint instead of restarting the full route unless requested.

## Overhead Map

1. Open the Canberra map during the live run.
2. Confirm the map subtitle references the next contact district when a combat stop is active.
3. Confirm threat rings and red threat markers are visible on the map.
4. Confirm combat checkpoints have a distinct threat-highlight ring around the normal checkpoint marker.
5. Confirm the footer reports:
   - `Combat Rehearsal: ...`
   - `Contact: ...`
   - `Threat: ...`

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries a `combatRehearsal` block and non-empty `detection.observers`.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md), [Docs/CYCLE_21_CONTACT_REHEARSAL.md](/Users/barbalet/github/milsim-pony/Docs/CYCLE_21_CONTACT_REHEARSAL.md), [Docs/CanberraReferenceGallery/README.md](/Users/barbalet/github/milsim-pony/Docs/CanberraReferenceGallery/README.md), and [MilsimPonyGame/Assets/Textures/README.md](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/Textures/README.md) all describe the cycle `21` combat-lane rehearsal.
