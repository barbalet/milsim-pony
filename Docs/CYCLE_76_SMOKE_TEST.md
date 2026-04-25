# Cycle 76 Smoke Test

## Restore Review Expiry Validation

1. Build and launch the macOS app in Debug.
2. Confirm the scene title reads `Canberra Restore Review Expiry Validation`.
3. Confirm the HUD title reads `Cycle 76 Restore Review Expiry`.
4. Confirm the title shell shows either persisted `Last Session:`, `Review Resume:`, `Review Guardrail:`, `Restore Preview:`, `Restore Readiness:`, `Manual Restore Arm:`, `Manual Restore Prompt:`, `Restore Choice:`, `Restore Selection:`, `Restore Fresh Start:`, `Restore Boundary Reset:`, `Restore Review Expiry:`, `Restore Execution Gate:`, `Restore Audit:`, `Restore Freshness:`, `Restore Retention:`, `Restore Cleanup Preview:`, and `Restore Cleanup:` lines or their no-persisted-state fallbacks.

## Review Target Expiry

1. Launch with a persisted review card that is not complete and belongs to the current scene and route.
2. Confirm the title shell shows `Restore Choice: preview Restore`.
3. Activate `Review Restore Target:` and confirm `Restore Selection: reviewed`.
4. Confirm `Restore Review Expiry: tracking` names the reviewed checkpoint target.
5. Start the demo and progress to a later checkpoint so the persisted restore target changes.
6. Confirm `Restore Review Expiry: cleared` names the old reviewed target and the new current target.
7. Confirm `Restore Selection:` returns to `pending review` for the new persisted target.
8. Confirm `Restore Execution Gate:` remains closed and no checkpoint restore is performed.

## Boundary Carryover

1. Review a restore target again from the title shell.
2. Activate `Start Demo` and confirm `Restore Fresh Start: confirmed over`.
3. Return to briefing or restart the route.
4. Confirm `Restore Boundary Reset: cleared` appears.
5. Confirm `Restore Review Expiry: cleared` appears for the same boundary.
6. Confirm Start Demo continues to begin from a fresh rehearsal start.
