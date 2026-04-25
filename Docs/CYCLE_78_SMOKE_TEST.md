# Cycle 78 Smoke Test

## Restore Review Intent Validation

1. Build and launch the macOS app in Debug.
2. Confirm the scene title reads `Canberra Restore Review Intent Validation`.
3. Confirm the HUD title reads `Cycle 78 Restore Review Intent`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Fresh Start:`, `Restore Boundary Reset:`, `Restore Review Expiry:`, `Restore Review Scope:`, `Restore Review Intent:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Intent Is Not Execution

1. Launch with a persisted review card that is not complete and belongs to the current scene and route.
2. Confirm the title shell shows `Restore Choice: preview Restore`.
3. Confirm `Restore Review Intent: unreviewed` names the restorable checkpoint before review.
4. Activate `Review Restore Target:`.
5. Confirm `Restore Selection: reviewed` names the same checkpoint.
6. Confirm `Restore Review Intent: reviewed` names the checkpoint and says it is not an execution token.
7. Confirm `Restore Execution Gate: closed / restore action not bound in this build` remains visible.

## Fresh Start Confirmation

1. Start the demo after reviewing a restore target.
2. Confirm `Restore Fresh Start: confirmed over` names the reviewed checkpoint.
3. Confirm `Restore Review Intent: fresh start confirmed` names the checkpoint and says there is no restore token.
4. Return to briefing or restart the route.
5. Confirm `Restore Boundary Reset: cleared` appears.
6. Confirm `Restore Review Intent:` returns to `unreviewed` or `none`, depending on whether a persisted restorable checkpoint still exists.
