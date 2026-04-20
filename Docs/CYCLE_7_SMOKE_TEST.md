# Cycle 7 Smoke Test

## Goal

Verify that the Canberra slice now behaves as a cycle `7` demo alpha: the app opens into a title shell, the route is playable from briefing through extraction, pause and settings work mid-run, and the Deakin corridor is dressed tightly enough that the intended line reads without developer narration.

## Build

Run:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Expected result:

- Build completes successfully.
- `MilsimPonyGame.app` is produced under `/tmp/MilsimPonyDerived/Build/Products/Debug/`.

## Launch

Run:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

Expected result:

- The app launches to the `Cycle 7 Demo Alpha` title shell rather than dropping straight into a live run.
- The centered shell reads as a mission briefing with a scripted route, while the HUD remains visible behind it at reduced opacity.
- The primary action begins the demo with `Space`, `Return`, or the `Start Demo` button.

## Title, Pause, And Settings Shells

Expected result:

- `Esc` pauses an active run and resumes it when pressed again from the pause shell.
- The pause shell offers `Resume`, `Restart Run`, `Settings`, and `Return To Briefing`.
- The settings shell lets the player change look sensitivity, HUD opacity, and invert-Y, and those values persist across a relaunch.

## Demo Route

Expected result:

- The title shell and HUD both describe the four-step script: `State Circle Cutthrough`, `Cross Street Junction`, `Deakin Service Lane`, and `Extraction Canopy`.
- The newly added `Stay West` and `Extraction Canopy` signposts help pull the player onto the west-side service line.
- The added corridor fences and hedges visually tighten the final stretch so the intended extraction lane is readable and harder to leave accidentally.

## Failure And Recovery

Expected result:

- Observer pressure can still trigger a fail state if the player crosses open sightlines for too long.
- On failure, the shell changes to the compromised state and offers both checkpoint retry and full restart.
- Retry resumes from the most recent checkpoint, while `Return To Briefing` resets the run and shows the title shell again.

## Win Condition

Expected result:

- Reaching `Extraction Canopy` transitions cleanly to the completion shell.
- The completion shell reports run time, distance, and restart count.
- `New Run` restarts immediately and `Return To Briefing` returns to the title shell without requiring developer intervention.

## Regression Check

Expected result:

- `W A S D`, mouse look, and `Shift` still control traversal during live gameplay.
- Detection, checkpoint progress, fail state, and route completion still update the HUD while the simulation is live.
- Pausing or opening settings freezes the gameplay simulation until the player returns to the run.
