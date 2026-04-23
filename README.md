# milsim-pony

`milsim-pony` is a macOS first-person military-simulation prototype built with SwiftUI, Metal, and a C-heavy gameplay core. The project is centered on Canberra, Australia, and is currently focused on proving large-scale terrain readability, a district-by-district street atlas, first-person traversal, scoped observation, and a reviewable gameplay loop that can grow into a fuller sniper-led milsim.

## Game Overview

The current default build launches into **Canberra Combat-Lane Rehearsal**, a cycle `21` pass that keeps the Woden-to-Belconnen route from cycle `20` but turns the locked review pack into a live contact rehearsal. The route is designed to prove that the world remains readable at distance through a 4x scope while the HUD, overhead map, cover cues, and observer pressure now expose the next combat lane without losing the named road and district read.

At the moment, the game is still a rehearsal build rather than a complete combat sandbox. You move on foot through the authored route, use the scope to inspect distant landmarks, and open the overhead map to keep your bearings, confirm which sector of Canberra you are in, read the named road network, and see where the next threat lane and watcher pressure live. The HUD, route markers, pause flow, settings screen, checkpoint restarts, and completion shell are already implemented so the build can be used as a repeatable review demo.

The broader project goal is a playable Canberra milsim with long-range combat support, stable distant rendering, and a usable sniper rifle. The current scene is the foundation for that work: it proves the world scale, sightlines, streaming behavior, district coverage, and scoped viewing path that later weapon systems will rely on.

## Current Demo Loop

1. Launch the game and begin from the briefing shell.
2. Spawn at the Woden town-centre staging point.
3. Walk or sprint through the authored cross-district checkpoints from Woden to Belconnen.
4. Raise the 4x scope at review points to inspect the Woden towers, lake edge, Civic skyline, West Basin handoff, Black Mountain skyline, and Belconnen approaches.
5. Open the overhead map whenever you need sector context, checkpoint progress, comparison-stop notes, contact-lane cues, threat rings, or the named road atlas.
6. Pause, restart, retry, or return to briefing as needed.

The repository also contains an earlier Parliament House escape scenario with detection, observer pressure, and checkpoint fallback logic. The default world manifest now points at the wider Canberra combat-rehearsal build instead of that smaller escape slice.

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

This build is not about firefights yet. The player is acting as a field observer moving through a guided Canberra contact rehearsal:

- Validate that major Canberra landmarks and arterial streets are visible and readable at long range.
- Confirm that scoped rendering remains stable across distant terrain and skyline silhouettes.
- Move between authored perches that test the Woden-to-Belconnen handoff instead of only isolated district slices.
- Use the overhead map to understand current location, sector, road network, contact lane, and route progress.
- Replay the route quickly to compare world-data, streaming, observer pressure, and rendering changes between cycles.

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

The active direction for the project is basin-scale Canberra coverage from Woden to Belconnen, with Lake Burley Griffin as a readable anchor, a district street atlas in the overhead map, and the 4x scope as the core validation tool. The live build is now on cycle `21`, using the locked review pack as the baseline for the first contact-lane rehearsal so the atlas, source gallery, texture library, cover cues, and live observer pressure can be reviewed in one pass.
