# milsim-pony

`milsim-pony` is a macOS first-person military-simulation prototype built with SwiftUI, Metal, and a C-heavy gameplay core. The project is centered on Canberra, Australia, and is currently focused on proving large-scale terrain readability, a district-by-district street atlas, first-person traversal, scoped observation, and a reviewable gameplay loop that can grow into a fuller sniper-led milsim.

## Game Overview

The current default build launches into **Canberra Save Resume Closeout**, a cycle `116` REVIEW recovery pass that keeps the Woden-to-Belconnen route, scoped rifle presentation, observer-audio feedback, mission-script hooks, surface-fidelity closeout, active-route map accuracy, guarded checkpoint restore, vegetation concealment/traversal feedback, CSM readiness profiling, repeatable packaging validation, tester delivery, lighting architecture decision, automated capture pipeline, landmark LOD switching, scenario-authored time-of-day lighting, Forward+ diagnostic lights, depth-aware scoped-safe edge anti-aliasing, the Rayleigh/Mie/ozone physical atmosphere baseline, the fallback-safe shadow-caster direct shadow path, scalable SDF-style HUD/scope/map text, bounded SSR with IBL/probe fallback, render graph scaffolding, authored audio mix controls, visible scoped firing feedback, live patrol-pair formation movement, source-backed district texture coverage, multi-route playability, scope optics, selectable collision-volume review, and explicit saved-run resume. The route is designed to prove that the world remains readable at distance through a 4x scope while the HUD, scoped reticle, overhead map, cover cues, observer audio, mission phase readouts, patrol pair state, LOS debug state, scan-halt-resume state, world audio state, route-selection state, `Last Session:` state, `Review Resume:` state, `Checkpoint Performance:` state, `Map Accuracy:` footer, `Collision Preview:` footer, `Collision Selection:` footer, `Collision Validation:` footer, `Collision Export:` footer, `Shadow Profile:` footer, `Distant LOD:` footer, `Water Reflection:` footer, `Packaging:` footer, `Tester Delivery:` footer, `Lighting Plan:` footer, `Time Of Day:` footer, `Anti-Aliasing:` footer, `Physical Atmosphere:` footer, `Indirect Rendering:` footer, `SDF UI:` footer, `Render Graph:` footer, `Audio Mix:` footer, material footers, weapon status, profiling baseline, collision-authoring inventory, environmental-motion status, surface-fidelity status, session-persistence status, `Restore Execution Design:`, `Restore Safety Checks:`, `Session Audio:`, `Scope Calibration:`, `Shot Feedback:`, `Vegetation Concealment:`, `CSM Profile:`, `LOD Reflection:`, restart-safe handoff rule, selection rules, checkpoint ownership, capture artifacts, LOD switching, time-of-day lighting, Forward+ diagnostic lights, scoped-safe AA, physical sky/haze controls, shadow fallback safety, crisp scalable UI labels, SSR/probe reflection controls, frame graph pass/resource validation, mixed route audio, player-facing rifle feedback, live formation patrol behavior, district texture acceptance evidence, playable rehearsal route choices, scope optics evidence, collision authoring review guidance, and save/resume evidence now agree on route expansion, optic usability, collision editing readiness, resumable rehearsal state, concealment readability, renderer profiling, LOD implementation, reflection evidence, packaging readiness, tester handoff, lighting architecture, restore safety, and repeatable review comparison.

At the moment, the game is still a rehearsal build rather than a complete combat sandbox. You move on foot through the authored route, use the scope to inspect distant landmarks, and open the overhead map to keep your bearings, confirm which sector of Canberra you are in, read the named road network, and see where the next threat lane and watcher pressure live. The HUD, route markers, pause flow, settings screen, checkpoint restarts, and completion shell are already implemented so the build can be used as a repeatable review demo.

The broader project goal is a playable Canberra milsim with long-range combat support, stable distant rendering, and a usable sniper rifle. The current scene is the foundation for that work: it proves the world scale, sightlines, streaming behavior, district coverage, and scoped viewing path that later weapon systems will rely on.

## Current Demo Loop

1. Launch the game and begin from the briefing shell.
2. Spawn at the Woden town-centre staging point.
3. Use the briefing route selector when needed, then walk or sprint through the selected authored checkpoint route.
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
- Confirm that scoped rendering remains stable across distant terrain and skyline silhouettes while `Scope Calibration:` reports practical range, drop, hold, calibrated mil spacing, compensated parallax, and edge stability cues, `CSM Profile:` reports the current shadow-map baseline plus planned cascade split targets, `LOD Reflection:` reports landmark impostor targets plus water reflection-probe evidence, `Packaging:` reports the release version policy, archive naming rule, manifest checks, `Tester Delivery:` reports the tester channel, notarization status, CI plan, delivery checklist, `Lighting Plan:` reports the scenario-lighting path plus clustered-lighting/render-graph decisions, `Time Of Day:` reports the authored hour, sun angle, ambient/diffuse light, and shadow multiplier, `Render Graph:` reports pass count, transient/imported resources, and pass order, `Audio Mix:` reports scene-authored category gains plus the persisted user master gain, and `Shot Feedback:` reports recoil and shot-result clarity.
- Move between authored perches that test the Woden-to-Belconnen handoff instead of only isolated district slices.
- Use the overhead map to understand current location, sector, road network, contact lane, and route progress.
- Replay the route quickly to compare world-data, streaming, observer pressure, audio feedback, mission hooks, alternate-route authoring, and rendering changes between cycles.

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

Validate the release packaging inputs:

```bash
Tools/package_release.sh --validate-only
```

Validate the tester distribution handoff:

```bash
Tools/package_release.sh --check-distribution
```

Create a timestamped release package when the local Xcode release toolchain is available:

```bash
Tools/package_release.sh
```

Run the current automated review capture:

```bash
Tools/capture_review.sh
```

Compare a new capture against a previous output directory:

```bash
Tools/capture_review.sh --baseline artifacts/captures/<previous-capture-directory>
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

The active direction for the project is now the Cycle `99`-`128` REVIEW recovery plan. Cycle `116` is the current live build, with automated capture, distant-building LOD implementation, configurable scenario time-of-day lighting, a Forward+ lighting start, scoped-safe anti-aliasing, a physical atmosphere baseline, fallback-safe shadow rendering, scalable SDF-style UI text, bounded SSR/IBL reflections, render graph scaffolding, authored audio mix controls, player-facing firing feedback, live group NPC patrol behavior, Black Mountain/West Basin source-backed texture coverage, multi-route playability, scope optics, collision authoring workflow, and save/resume closeout complete for their canonical review scope. The next cycle continues the partially complete REVIEW.md items with Cycle `117` formal performance profiling in [Docs/DEVELOPMENT_BACKLOG.md](/Users/barbalet/github/milsim-pony/Docs/DEVELOPMENT_BACKLOG.md).
