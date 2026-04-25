# Cycle 116 Smoke Test - Save Resume Closeout

## Purpose

Verify that saved session state is more than a review note: it can restore a saved route-bound checkpoint target and report checkpoint performance across launches.

## Checks

1. Launch the app and confirm the title scene reports `Canberra Save Resume Closeout`.
2. Start Demo, reach at least one checkpoint, then pause or return to briefing.
3. Confirm overlay/title lines include:
   - `Last Session:` with route label, checkpoint count, difficulty, sector, and state.
   - `Review Resume:` with next checkpoint plus map/scope review state.
   - `Checkpoint Performance:` with checkpoint count, travelled meters, elapsed seconds, restart count, and fail count.
4. Relaunch or return to the briefing shell and confirm `Resume Saved Run:` is enabled when the stored target is fresh and valid.
5. Activate `Resume Saved Run:` and confirm the saved route is rebound before checkpoint progress is restored.
6. Verify `Restore Safety Checks:` reports identity, target, and freshness pass before restore execution.
7. Confirm the run resumes at the saved checkpoint target and the title/overlay reports the consumed restore review token.
8. Run `Tools/package_release.sh --validate-only` and confirm Cycle 116 version and docs validate.
9. Run `Tools/capture_review.sh --validate-only` and confirm capture tooling defaults to Cycle 116.

## Expected Result

The saved review card stores route identity, checkpoint progress, map/scope state, and checkpoint performance metrics. The title screen exposes a clear saved-run resume action, and restore execution rebinds the saved route before applying checkpoint progress.
