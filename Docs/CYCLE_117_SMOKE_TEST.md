# Cycle 117 Smoke Test - Formal Profiling

## Status

Cycle `117` is complete. This document remains the executable profiling smoke test, while the closed bottleneck review lives in [CYCLE_117_PROFILING_REVIEW.md](CYCLE_117_PROFILING_REVIEW.md).

## Purpose

Capture a formal CPU/GPU profiling artifact before renderer-heavy work continues. The output must identify the main bottlenecks for shadow rendering, scene geometry, presentation/postprocess work, world/core simulation, line-of-sight sampling, and frame pacing.

## Profiling Command

```sh
Tools/profile_cycle117.sh
```

The profiling build uses the temporary product name `MilsimPonyProfile117` and bundle identifier `com.milsimpony.game.profile117` by default so Instruments does not attach the trace to an older packaged `MilsimPonyGame.app` release registered with Launch Services.
The script launches that profiling executable directly and attaches `xctrace` to the captured PID with `--no-prompt`. For the completed review, direct target `Metal System Trace` export was blocked by Instruments `Document Missing Template Error`, so the closure uses a target-correct Time Profiler trace plus an exportable all-process Metal System Trace fallback.

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

Cycle `117` is closed only because stored trace artifacts, exported TOCs, and the bottleneck report exist. A successful script validation by itself does not close future profiling cycles.

## Current Attempt

- Earlier trace artifact captured: `artifacts/profiling/cycle117-20260429-035159/MilsimPonyGame-cycle117.trace`
- Earlier TOC export captured: `artifacts/profiling/cycle117-20260429-035159/trace_toc.xml`
- Earlier blocker: the exported TOC reported the process path as the older registered release bundle under `artifacts/release/MilsimPonyGame-v0.9.0-b9-20260420-220715/MilsimPonyGame.app`, even though the profiler launched the Debug executable under `/tmp/MilsimPonyProfileDerived`.
- Mitigation now in tooling: the profiler builds `MilsimPonyProfile117.app` with bundle identifier `com.milsimpony.game.profile117`, launches its executable directly, and attaches `xctrace` to the captured PID with `--no-prompt`.
- Completed target-correct CPU artifact: `artifacts/profiling/cycle117-time-profiler-current.trace`
- Completed target-correct CPU TOC: `artifacts/profiling/cycle117-time-profiler-current-toc.xml`
- Completed CPU sample export: `artifacts/profiling/cycle117-time-profile-current.xml`
- Completed exportable Metal fallback artifact: `artifacts/profiling/cycle117-metal-system-live.trace`
- Completed Metal fallback TOC: `artifacts/profiling/cycle117-metal-system-live-toc.xml`
- Direct target-launched `Metal System Trace` limitation: Instruments saved a trace bundle but TOC export failed with `Document Missing Template Error`; this is recorded in [CYCLE_117_PROFILING_REVIEW.md](CYCLE_117_PROFILING_REVIEW.md) for Cycle `165` follow-up.
- Cycle `117` is closed by the stored artifacts and bottleneck report.
