# Cycle 77 Smoke Test

## Restore Review Scope Validation

1. Build and launch the macOS app in Debug.
2. Confirm the scene title reads `Canberra Restore Review Scope Validation`.
3. Confirm the HUD title reads `Cycle 77 Restore Review Scope`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Fresh Start:`, `Restore Boundary Reset:`, `Restore Review Expiry:`, `Restore Review Scope:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Runtime-Only Review

1. Launch with a persisted review card that is not complete and belongs to the current scene and route.
2. Confirm the title shell shows `Restore Choice: preview Restore`.
3. Confirm `Restore Review Scope: persisted target` names the restorable checkpoint before review.
4. Activate `Review Restore Target:`.
5. Confirm `Restore Selection: reviewed` names the same checkpoint.
6. Confirm `Restore Review Scope: runtime-only review of` names the checkpoint and says it is not persisted.
7. Start the demo and confirm `Restore Fresh Start: confirmed over` appears while `Restore Execution Gate:` remains closed.

## Scope Reset

1. Return to briefing or restart the route after reviewing a restore target.
2. Confirm `Restore Boundary Reset: cleared` appears.
3. Confirm `Restore Review Scope: persisted target` returns when the persisted review card still has a restorable checkpoint.
4. Progress until the persisted target changes.
5. Confirm `Restore Review Expiry: cleared` appears and `Restore Review Scope:` no longer claims a runtime-only review of the old target.
