# Cycle 122 Smoke Test - Mission Scripting Expansion

## Status

Cycle `122` is complete for conditional mission scripting.

## Implementation Evidence

- Mission phase data now supports `failOnObserverAlert`, `failOnSuspicionRatio`, `timeLimitSeconds`, and `alternateObjective`.
- `GameSession` evaluates the active checkpoint phase while playing and updates `Mission Runtime:` with condition state, timer, suspicion ratio, and alternate objective.
- `GameCoreForceRouteFailure()` lets mission scripts fail the route cleanly without fabricating a HUD-only state.
- The Canberra scene mission script now includes alert failure, suspicion thresholds, time limits, and alternates across the main route phases.

## Smoke Steps

1. Start the route and confirm `Mission Runtime:` names the current mission map code.
2. Stay in a phase until the timer or suspicion ratio approaches its threshold and confirm the line updates.
3. Trigger an authored alert-fail phase, such as a scope perch or final extraction watcher.
4. Confirm the route enters the compromised/failure shell through `GameCoreForceRouteFailure()`.
5. Retry from checkpoint and confirm the mission runtime resets for the current phase.

## Remaining Follow-Up

Cycle `148` still owns the full player-facing win/fail loop, and Cycle `149` expands mission objective variants beyond this conditional checkpoint scripting layer.
