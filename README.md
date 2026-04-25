# milsim-pony

`milsim-pony` is a macOS first-person military-simulation prototype built with SwiftUI, Metal, and a C-heavy gameplay core. The project is centered on Canberra, Australia, and is currently focused on proving large-scale terrain readability, a district-by-district street atlas, first-person traversal, scoped observation, and a reviewable gameplay loop that can grow into a fuller sniper-led milsim.

## Game Overview

The current default build launches into **Canberra Third Rehearsal Route Authoring Validation**, a cycle `89` pass that keeps the Woden-to-Belconnen route, scoped rifle presentation, observer-audio feedback, mission-script hooks, surface-fidelity closeout, review-resume card, persistence guardrails, restore-target preview, restore-readiness report, manual-restore arming, restore-prompt contract, restore-execution gate, restore-audit trail, restore-freshness policy, restore-retention policy, restore-cleanup preview, guarded stale-card cleanup execution, visible preview-only restore target choice, restore-selection audit, fresh-start guard, restore boundary reset, restore review expiry, restore review scope, restore review intent, muzzle-feedback, profiling-baseline, patrol-pair lines, `LOS Debug:`, `Scan State:`, `Scan Halt Resume:`, `World Audio:`, alternate-route live binding, active-route map accuracy, Black Mountain/Telstra/Bruce material assignments, and West Basin/Yarralumla shoreline, vegetation, road, hardscape, facade, and water material assignments locked while adding a third authored rehearsal route with multi-route map previews and route-specific watcher coverage. The route is designed to prove that the world remains readable at distance through a 4x scope while the HUD, scoped reticle, overhead map, cover cues, observer audio, mission phase readouts, patrol pair state, LOS debug state, scan-halt-resume state, world audio state, alternate live-binding state, `Map Accuracy:` footer, `Black Mountain Materials:` footer, `West Basin Materials:` footer, weapon status, muzzle flash placeholder, recoil recovery, miss classification, scope holdover, parallax state, crack-thump timing, frame/core/LOS/world profiling baseline, active-route binding status, alternate-route preview paths, staged-route distance and footprint, binding-gate status, selection-lock rule, activation-guard rule, rollback-guard rule, commit-gate rule, dry-run rule, promotion-readiness rule, promotion-audit rule, restart-boundary rule, handoff-arming rule, handoff-confirmation rule, release-gate rule, live-switch preflight rule, collision-authoring inventory, environmental-motion status, surface-fidelity status, session-persistence status, restore-target preview, restore-readiness report, manual-restore arming, restore-prompt contract, restore-choice preview, restore-selection audit, restore fresh-start guard, restore boundary reset, restore review expiry, restore review scope, restore review intent, restore-execution gate, restore-audit trail, restore-freshness policy, restore-retention policy, restore-cleanup preview, restore-cleanup execution, restart-safe handoff rule, selection rules, and checkpoint ownership now agree on route expansion without losing the named road and district read.

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

The active direction for the project is basin-scale Canberra coverage from Woden to Belconnen, with Lake Burley Griffin as a readable anchor, a district street atlas in the overhead map, and the 4x scope as the core validation tool. The live build is now on cycle `89`, using the paired-observer route as the stable baseline while the selected alternate route can be armed from briefing and rebound as the active checkpoint sequence before live movement begins. The first alternate rehearsal route now carries live-binding proof, map-accuracy validation, Black Mountain/Telstra/Bruce material closeout, and West Basin/Yarralumla vegetation-water closeout, while the third-route authoring pass adds `West Basin To Ginninderra Shore Thread` as a preview-only candidate with its own map path, readiness metadata, and north-west watcher geometry. Route expansion continues alongside preview geometry, selection-readiness rules, checkpoint ownership metadata, an explicit staged-loader state, route metrics, binding-gate validation, briefing-only selection locking, guarded activation, primary-route rollback guarding, staged-route commit gating, non-mutating dry-run comparison, promotion-readiness review, promotion-audit reporting, restart-boundary rehearsal, handoff-arming preview, handoff-confirmation reporting, release-gate reporting, live-switch preflight reporting, collision-authoring readiness reporting, scene-authored environmental motion, lake-surface material binding, water ripples, screen-space surface depth, road material breakup, landmark facade breakup, surface-fidelity closeout reporting, session-persistence readiness reporting, last-review state persistence, review-resume capture context, persistence guardrails, restore-target previewing, restore-readiness reporting, manual-restore arming, restore-prompt contract reporting, restore-choice preview reporting, restore-selection audit reporting, restore fresh-start guard reporting, restore boundary reset reporting, restore review-expiry reporting, restore review-scope reporting, restore review-intent reporting, restore-execution gate reporting, restore-audit trail reporting, restore-freshness policy reporting, restore-retention policy reporting, restore-cleanup preview reporting, and guarded stale-card cleanup execution before automatic checkpoint restore is enabled.
