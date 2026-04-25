# Cycle 84 Smoke Test - World And Movement Audio Bed

## Launch And Shell

- Build and launch the `MilsimPonyGame` scheme.
- Confirm the briefing shell identifies `Canberra World Movement Audio Validation`.
- Start the route and confirm the HUD contains `World Audio:` along with `Observer Feedback:`, `Patrol Pairs:`, `LOS Debug:`, `Scan State:`, and `Scan Halt Resume:`.

## Footsteps

- Walk forward on grounded terrain and confirm soft step ticks play at a slower cadence.
- Hold sprint while moving and confirm the step cadence tightens.
- Stop moving and confirm `World Audio:` reports an idle grounded movement state.

## Scope Toggle

- Press `Space` during live play to raise the 4x scope and confirm a short scope raise cue plays.
- Press `Space` again to lower the scope and confirm the lower cue plays.
- Confirm `World Audio:` changes between scope raised and scope lowered cue states.

## Ambient Bed And Alert Mix

- Stand still in the live route and confirm a low basin ambient bed repeats quietly.
- Trigger observer memory or relay state and confirm the existing alert cue still plays over the basin bed.
- Confirm `World Audio:` reports the current threat mix, such as quiet, relay, memory, exposed, or compromised.

## Regression

- Fire the rifle and confirm shot, bolt, impact, muzzle feedback, and shot timing still update.
- Use a patrol pair contact lane and confirm scan-halt-resume, LOS debug, and observer feedback lines still update.
- Restart from a checkpoint and confirm movement, scope, ambient, and alert audio resume without crashing.
