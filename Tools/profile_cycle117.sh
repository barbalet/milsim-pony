#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project_path="$repo_root/MilsimPonyGame.xcodeproj"
scheme_name="MilsimPonyGame"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/MilsimPonyProfileDerived}"
profile_root="${PROFILE_ROOT:-$repo_root/artifacts/profiling}"
cycle="${PROFILE_CYCLE:-117}"
timestamp="$(date -u +"%Y%m%d-%H%M%S")"
output_dir="$profile_root/cycle${cycle}-$timestamp"
app_path=""
launch_path=""
bundle_identifier=""
executable_name=""
profile_bundle_identifier="${PROFILE_BUNDLE_IDENTIFIER:-com.milsimpony.game.profile117}"
profile_product_name="${PROFILE_PRODUCT_NAME:-MilsimPonyProfile117}"
lsregister_path="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
trace_template="${PROFILE_TEMPLATE:-Metal System Trace}"
time_limit="${PROFILE_TIME_LIMIT:-20s}"
skip_build=0
validate_only=0
launched_pid=""

usage() {
  cat <<EOF
Usage: Tools/profile_cycle117.sh [--validate-only] [--skip-build] [--app APP] [--output DIR] [--template NAME] [--time-limit DURATION]

  --validate-only       Validate the profiling toolchain without building or launching the app.
  --skip-build          Use the Debug app already in DERIVED_DATA_PATH.
  --app APP             Profile a prebuilt MilsimPonyGame.app.
  --output DIR          Write the trace and report to DIR.
  --template NAME       xctrace template name. Defaults to "Metal System Trace".
  --time-limit DURATION xctrace duration. Defaults to 20s.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-only)
      validate_only=1
      ;;
    --skip-build)
      skip_build=1
      ;;
    --app)
      app_path="$2"
      shift
      ;;
    --output)
      output_dir="$2"
      shift
      ;;
    --template)
      trace_template="$2"
      shift
      ;;
    --time-limit)
      time_limit="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

app_path_was_default=0
if [[ -z "$app_path" ]]; then
  app_path="$derived_data_path/Build/Products/Debug/${profile_product_name}.app"
  app_path_was_default=1
fi

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

validate_tools() {
  require_tool xcodebuild
  require_tool xctrace
  require_tool osascript
  require_tool shasum

  if [[ ! -d "$project_path" ]]; then
    echo "Missing project: $project_path" >&2
    exit 1
  fi
}

read_bundle_identifier() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$app_path/Contents/Info.plist"
}

read_executable_name() {
  /usr/libexec/PlistBuddy -c "Print :CFBundleExecutable" "$app_path/Contents/Info.plist"
}

prepare_launch_services() {
  bundle_identifier="$(read_bundle_identifier)"
  if [[ -n "$bundle_identifier" ]]; then
    osascript -e "tell application id \"$bundle_identifier\" to quit" >/dev/null 2>&1 || true
  fi

  if [[ "$bundle_identifier" != "com.milsimpony.game" ]]; then
    osascript -e 'tell application id "com.milsimpony.game" to quit' >/dev/null 2>&1 || true
  fi

  if [[ -n "$bundle_identifier" ]]; then
    sleep 1
  fi

  if [[ -x "$lsregister_path" ]]; then
    "$lsregister_path" -f -R -trusted "$app_path" >/dev/null 2>&1 || true
  fi
}

build_app() {
  xcodebuild \
    -project "$project_path" \
    -scheme "$scheme_name" \
    -configuration Debug \
    -derivedDataPath "$derived_data_path" \
    PRODUCT_BUNDLE_IDENTIFIER="$profile_bundle_identifier" \
    PRODUCT_NAME="$profile_product_name" \
    CODE_SIGNING_ALLOWED=NO \
    build
}

write_report_header() {
  mkdir -p "$output_dir"
  cat >"$output_dir/cycle${cycle}_profiling_report.md" <<EOF
# Cycle ${cycle} Formal Profiling Report

- Captured at UTC: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- App: $app_path
- Launch executable: $launch_path
- Bundle identifier: $bundle_identifier
- Requested profiling bundle identifier: $profile_bundle_identifier
- Requested profiling product name: $profile_product_name
- Derived data: $derived_data_path
- xctrace template: $trace_template
- Time limit: $time_limit
- Capture method: launch profiling executable, then attach xctrace to its PID
- Closure status: pending trace review

## Required Review

- Confirm the trace opens in Instruments.
- Confirm the report lists the profiling app PID and `xctrace` was run with `--no-prompt`.
- Confirm the trace TOC process path resolves to the freshly built app, not an older registered bundle.
- Record CPU hotspots, GPU/Metal encoder pressure, frame pacing outliers, shadow pass cost, scene pass cost, and presentation/postprocess cost.
- Compare the trace against the HUD "Profile Baseline:", "CSM Profile:", "LOD Reflection:", and "Lighting Plan:" lines.
- Update Docs/CYCLE_117_SMOKE_TEST.md, Docs/DEVELOPMENT_BACKLOG.md, REVIEW.md, and REVIEW2.md only after the bottleneck notes are written.

EOF
}

main() {
  validate_tools

  if [[ "$validate_only" -eq 1 ]]; then
    mkdir -p "$output_dir"
    printf 'Cycle %s profiling tooling validated. Output root: %s\n' "$cycle" "$output_dir"
    exit 0
  fi

  if [[ "$skip_build" -eq 0 ]]; then
    build_app
  fi

  if [[ ! -d "$app_path" ]]; then
    echo "App bundle not found: $app_path" >&2
    exit 1
  fi

  executable_name="$(read_executable_name)"
  launch_path="$app_path/Contents/MacOS/$executable_name"
  if [[ ! -x "$launch_path" ]]; then
    echo "App executable not found: $launch_path" >&2
    exit 1
  fi
  prepare_launch_services

  local trace_path="$output_dir/MilsimPonyGame-cycle${cycle}.trace"
  local log_path="$output_dir/xctrace.log"
  local app_log_path="$output_dir/app.log"
  write_report_header

  "$launch_path" >"$app_log_path" 2>&1 &
  launched_pid="$!"
  sleep 2

  if ! kill -0 "$launched_pid" >/dev/null 2>&1; then
    {
      printf '## App Launch Status\n\n'
      printf 'Profiling app exited before tracing could start.\n\n'
      printf 'See `%s` for the raw app output.\n' "$app_log_path"
    } >>"$output_dir/cycle${cycle}_profiling_report.md"
    echo "Profiling app exited before trace start. Report written to $output_dir/cycle${cycle}_profiling_report.md" >&2
    exit 1
  fi

  set +e
  xctrace record \
    --no-prompt \
    --template "$trace_template" \
    --time-limit "$time_limit" \
    --output "$trace_path" \
    --attach "$launched_pid" >"$log_path" 2>&1
  local trace_status=$?
  set -e

  kill "$launched_pid" >/dev/null 2>&1 || true

  if [[ "$trace_status" -ne 0 && ! -d "$trace_path" ]]; then
    {
      printf '## xctrace Status\n\n'
      printf 'Trace capture failed with exit code `%d`.\n\n' "$trace_status"
      printf 'See `%s` for the raw xctrace output.\n' "$log_path"
    } >>"$output_dir/cycle${cycle}_profiling_report.md"
    echo "xctrace failed. Report written to $output_dir/cycle${cycle}_profiling_report.md" >&2
    exit "$trace_status"
  fi

  local trace_hash
  trace_hash="$(find "$trace_path" -maxdepth 2 -type f -print0 2>/dev/null | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"

  {
    printf '## Trace Artifact\n\n'
    printf '%s\n' "- Trace: \`$trace_path\`"
    printf '%s\n' "- Aggregate trace hash: \`$trace_hash\`"
    printf '%s\n' "- Attached PID: \`$launched_pid\`"
    printf '%s\n\n' "- xctrace log: \`$log_path\`"
    printf '%s\n\n' "- App log: \`$app_log_path\`"
    if [[ "$trace_status" -ne 0 ]]; then
      printf 'xctrace returned warning exit code `%d`, but the trace bundle was written. Review the log before closing the cycle.\n\n' "$trace_status"
    fi
    printf 'Cycle `%s` remains open until the bottleneck review is written and linked from the backlog.\n' "$cycle"
  } >>"$output_dir/cycle${cycle}_profiling_report.md"

  printf 'Cycle %s profiling trace written to %s\n' "$cycle" "$output_dir"
}

main "$@"
