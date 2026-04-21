# milsim-pony

`milsim-pony` is a macOS first-person military-simulation prototype built with SwiftUI, Metal, and a C-heavy gameplay core. The project is centered on Canberra, Australia, and is currently focused on proving large-scale terrain readability, first-person traversal, scoped observation, and a reviewable gameplay loop that can grow into a fuller sniper-led milsim.

## Game Overview

The current default build launches into **Canberra Scope Validation Review**, a basin-scale demo that starts on an elevated perch above the east basin and sends the player across a sequence of authored observation points. The route is designed to confirm that the world remains readable at distance through a 4x scope, especially around Lake Burley Griffin, the Parliament axis, Woden, Black Mountain, and the Belconnen skyline.

At the moment, the game is more of a traversal and observation prototype than a complete combat sandbox. You move on foot through the authored route, use the scope to inspect distant landmarks, and open the overhead map to keep your bearings and confirm which sector of Canberra you are in. The HUD, route markers, pause flow, settings screen, checkpoint restarts, and completion shell are already implemented so the build can be used as a repeatable review demo.

The broader project goal is a playable Canberra milsim with long-range combat support, stable distant rendering, and a usable sniper rifle. The current scene is the foundation for that work: it proves the world scale, sightlines, streaming behavior, and scoped viewing path that later weapon systems will rely on.

## Current Demo Loop

1. Launch the game and begin from the briefing shell.
2. Spawn at the East Basin scope terrace.
3. Walk or sprint between the authored landmark-validation checkpoints.
4. Raise the 4x scope at review points to inspect distant Canberra features.
5. Open the overhead map whenever you need sector context or checkpoint progress.
6. Pause, restart, retry, or return to briefing as needed.

The repository also contains an earlier Parliament House escape scenario with detection, observer pressure, and checkpoint fallback logic. The default world manifest currently points at the wider Canberra basin review build instead of that smaller escape slice.

## Controls

Click inside the game window first so the Metal view becomes the active input target.

| Key / Input | Action | Behavior |
| --- | --- | --- |
| `W` | Move forward | Continuous grounded movement |
| `A` | Strafe left | Continuous grounded movement |
| `S` | Move backward | Continuous grounded movement |
| `D` | Strafe right | Continuous grounded movement |
| `Shift` | Sprint | Hold while moving to use sprint speed |
| `Mouse Move` | Look | First-person camera look |
| `Space` | Interact / confirm / scope | Starts the demo from briefing, confirms menu actions, and raises or lowers the 4x scope during live play |
| `Return` / `Enter` | Interact / confirm | Same confirm path as `Space` for briefing and menu actions |
| `M` | Toggle overhead map | Opens or closes the Canberra overhead map when available |
| `R` | Restart route / retry checkpoint | Restarts the run or retries from the latest checkpoint flow |
| `Esc` | Pause / resume | Pauses live play, resumes from pause, and closes Settings when that panel is open |

## What The Player Is Doing

This build is not about firefights yet. The player is acting as a field observer moving through a guided Canberra survey route:

- Validate that major Canberra landmarks are visible and readable at long range.
- Confirm that scoped rendering remains stable across distant terrain and skyline silhouettes.
- Move between authored perches that test different basin sightlines.
- Use the overhead map to understand current location, sector, and route progress.
- Replay the route quickly to compare world-data, streaming, and rendering changes between cycles.

## Build And Run

Requirements:

- macOS
- Xcode with Metal support

Build from the repository root:

```bash
xcodebuild -project MilsimPonyGame.xcodeproj -scheme MilsimPonyGame -configuration Debug -derivedDataPath /tmp/MilsimPonyDerived CODE_SIGNING_ALLOWED=NO build
```

Launch the built app:

```bash
open /tmp/MilsimPonyDerived/Build/Products/Debug/MilsimPonyGame.app
```

You can also open [MilsimPonyGame.xcodeproj](/Users/barbalet/github/milsim-pony/MilsimPonyGame.xcodeproj) in Xcode and run the `MilsimPonyGame` scheme directly.

## Repository Layout

- [MilsimPonyGame/App](/Users/barbalet/github/milsim-pony/MilsimPonyGame/App) contains the SwiftUI app shell and root view.
- [MilsimPonyGame/Renderer](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Renderer) contains the Metal view, renderer, shaders, and render helpers.
- [MilsimPonyGame/Gameplay](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Gameplay) contains session state, input bindings, HUD state, and demo flow control.
- [MilsimPonyGame/Core](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Core) contains the C gameplay core and shared engine interfaces.
- [MilsimPonyGame/World](/Users/barbalet/github/milsim-pony/MilsimPonyGame/World) contains world bootstrap and scene/world-data decoding.
- [MilsimPonyGame/Assets](/Users/barbalet/github/milsim-pony/MilsimPonyGame/Assets) contains art assets and Canberra world data.
- [Docs](/Users/barbalet/github/milsim-pony/Docs) contains cycle smoke tests, release notes, input notes, and planning documents.

## Current Focus

The active direction for the project is basin-scale Canberra coverage from Woden to Belconnen, with Lake Burley Griffin as a readable anchor and the 4x scope as the core validation tool. The next major milestone is turning this observation route into a fuller sniper-capable milsim without losing the large-world readability the current demo is built to prove.
