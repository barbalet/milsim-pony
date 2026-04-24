# Cycle 29 Smoke Test

Verify that the Canberra demo now behaves as a cycle `29` observer-audio and feedback-polish pass: the shell advertises the new framing, the scoped and HUD threat readouts distinguish observer states, and audio cues support relay escalation and recovery without changing the Woden-to-Belconnen route.

## Boot And Shell

1. Build and launch `MilsimPonyGame`.
2. Stay on the title shell before starting.
3. Confirm the scene title reads `Canberra Observer Feedback Audio Validation`.
4. Confirm the HUD title reads `Cycle 29 Observer Audio And Feedback Polish`.
5. Confirm the planning notes mention observer audio, relay escalation, and line-of-sight recovery.

## Live Route

1. Start from `Woden Town Centre Staging`.
2. Enter the Woden paired-observer lane and confirm a first exposure plays the acquire alert cue.
3. Move so the supporting observer receives shared alert pressure and confirm a separate relay cue plays.
4. Break line of sight until suspicion decays and confirm the HUD reports `Observer Feedback: clear audio` after recovery.
5. Confirm checkpoint retry and full restart still behave as in the cycle `28` route.

## Scoped Feedback

1. Raise the 4x scope while an observer has direct sight.
2. Confirm the scope status names the seeing observer and the reticle warms toward the exposed alert tint.
3. Break direct sight while alert memory remains active.
4. Confirm the scope status names the alerted observer with memory time and the reticle shifts to the relay/memory tint.
5. Fire at an observer and confirm the existing shot, bolt, impact, and hit-confirm cues still play.

## Overlay And Map

1. Confirm the overlay includes an `Observer Feedback:` line.
2. Confirm the line distinguishes at least `exposed`, `relay`, `memory`, `cooling`, or `clear` while moving through a contact lane.
3. Open the Canberra map and confirm threat rings and observer-state counts still update.
4. Confirm route, cover, contact, difficulty, ballistics, and profiler lines still appear.

## Data And Docs

1. Confirm [canberra_basin_preview_scene.json](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/Scenes/canberra_basin_preview_scene.json) carries the cycle `29` label and observer-audio summary.
2. Confirm [README.md](/Users/barbalet/github/milsim-pony/README.md) describes the cycle `29` observer feedback audio validation build.
