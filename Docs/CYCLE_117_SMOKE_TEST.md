# Cycle 117 Smoke Test - Formal Profiling

## Status

Cycle `117` is open. This document is the executable profiling smoke test, not proof that profiling has already been reviewed.

## Purpose

Capture a formal CPU/GPU profiling artifact before renderer-heavy work continues. The output must identify the main bottlenecks for shadow rendering, scene geometry, presentation/postprocess work, world/core simulation, line-of-sight sampling, and frame pacing.

## Profiling Command

```sh
Tools/profile_cycle117.sh
```

The profiling build uses the temporary product name `MilsimPonyProfile117` and bundle identifier `com.milsimpony.game.profile117` by default so Instruments does not attach the trace to an older packaged `MilsimPonyGame.app` release registered with Launch Services.
The script launches that profiling executable directly and attaches `xctrace` to the captured PID with `--no-prompt`.

Useful validation-only check:

```sh
Tools/profile_cycle117.sh --validate-only
```

The default output path is `artifacts/profiling/cycle117-<utc>/`.

## Required Evidence

- `MilsimPonyGame-cycle117.trace` or an equivalent Instruments trace exists.
- `cycle117_profiling_report.md` names the capture time, template, app path, and trace artifact.
- The report lists the attached profiling PID and the raw `xctrace.log` has no pending interactive prompt.
- The exported trace TOC confirms the launched profiling process belongs to the freshly built profiling app under the derived-data path, or at minimum no longer resolves to the older `artifacts/release` bundle.
- Bottleneck notes call out CPU hotspots, GPU/Metal encoder pressure, frame pacing outliers, shadow pass cost, scene pass cost, and presentation/postprocess cost.
- The review compares the trace against the in-game `Profile Baseline:`, `CSM Profile:`, `LOD Reflection:`, and `Lighting Plan:` HUD lines.
- [DEVELOPMENT_BACKLOG.md](DEVELOPMENT_BACKLOG.md), [REVIEW.md](../REVIEW.md), and [REVIEW2.md](../REVIEW2.md) are updated only after the trace review exists.

## Pass Criteria

Cycle `117` can be closed only when the trace opens in Instruments and the bottleneck report is linked from the backlog. A successful script validation by itself does not close the cycle.

## Current Attempt

- Earlier trace artifact captured: `artifacts/profiling/cycle117-20260429-035159/MilsimPonyGame-cycle117.trace`
- Earlier TOC export captured: `artifacts/profiling/cycle117-20260429-035159/trace_toc.xml`
- Earlier blocker: the exported TOC reported the process path as the older registered release bundle under `artifacts/release/MilsimPonyGame-v0.9.0-b9-20260420-220715/MilsimPonyGame.app`, even though the profiler launched the Debug executable under `/tmp/MilsimPonyProfileDerived`.
- Mitigation now in tooling: the profiler builds `MilsimPonyProfile117.app` with bundle identifier `com.milsimpony.game.profile117`, launches its executable directly, and attaches `xctrace` to the captured PID with `--no-prompt`.
- Current blocker: a clean noninteractive attach trace and bottleneck notes still need to be captured against `MilsimPonyProfile117.app`.
- Cycle `117` therefore remains open until the target-correct trace and bottleneck notes are written against the current build.
