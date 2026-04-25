# Tester Distribution Pipeline

Cycle `97` keeps tester sharing deliberately simple and reviewable. The release package is still a local macOS zip, but it now has a scripted distribution gate before anybody treats it as tester-ready.

## Version And Archive Policy

- Marketing version: `0.98.0`
- Build number: `98`
- Release cycle: `98`
- Archive pattern: `MilsimPonyGame-v0.98.0-b98-cycle98-<utc>.zip`

## Distribution Gate

Run the non-building gate first:

```bash
Tools/package_release.sh --check-distribution
```

This validates the release inputs, checks the tester handoff docs, confirms the expected archive/version policy, and reports whether the local machine has access to `xcrun notarytool`.

## Package Gate

When the local Xcode release toolchain is complete, run:

```bash
Tools/package_release.sh
```

The script builds Release, validates the app version, copies the release docs, writes `build_manifest.txt`, creates the zip, and smoke-checks the packaged app, executable, manifest, and archive.

## Notarization Plan

Notarization is credential-gated for now. Before sharing outside a local review group:

- Install the missing Xcode Metal release toolchain if Release builds fail at Metal compilation.
- Configure an Apple notary profile with `xcrun notarytool store-credentials`.
- Submit the zip or app using the stored profile.
- Staple the notarization ticket when Apple accepts the upload.
- Record the notarization result or blocker in the tester handoff note.

## CI Plan

The first CI gate should run:

```bash
Tools/package_release.sh --validate-only
Tools/package_release.sh --check-distribution
```

The packaging job should only upload tester artifacts after the Release build, package smoke checks, and notarization step all pass or after a reviewer explicitly accepts a documented local-only build.

## SDF UI Scope

SDF font/UI rendering is scoped for later polish rather than mixed into tester delivery. The first SDF pass should focus on HUD/map text crispness, monospaced diagnostic lines, scope overlay labels, and high-DPI readability, then compare screenshots against the current SwiftUI text path before replacing it.
