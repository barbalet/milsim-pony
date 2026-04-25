#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project_path="$repo_root/MilsimPonyGame.xcodeproj"
scheme_name="MilsimPonyGame"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/MilsimPonyCaptureDerived}"
captures_root="${CAPTURES_ROOT:-$repo_root/artifacts/captures}"
cycle="${CAPTURE_CYCLE:-116}"
timestamp="$(date -u +"%Y%m%d-%H%M%S")"
output_dir="$captures_root/cycle${cycle}-$timestamp"
baseline_dir=""
app_path=""
skip_build=0
validate_only=0
keep_running=0
diff_threshold="${CAPTURE_DIFF_THRESHOLD:-10}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/milsim-pony-swift-module-cache}"
launched_pid=""

usage() {
  cat <<EOF
Usage: Tools/capture_review.sh [--baseline DIR] [--output DIR] [--app APP] [--skip-build] [--validate-only] [--keep-running]

  --baseline DIR    Compare captured PNGs with matching filenames in DIR.
  --output DIR      Write captures, diffs, and manifest to DIR.
  --app APP         Launch a prebuilt MilsimPonyGame.app.
  --skip-build      Use the Debug app already in DERIVED_DATA_PATH.
  --validate-only   Validate the capture tooling without launching the app.
  --keep-running    Leave the app running after captures complete.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --baseline)
      baseline_dir="$2"
      shift
      ;;
    --output)
      output_dir="$2"
      shift
      ;;
    --app)
      app_path="$2"
      shift
      ;;
    --skip-build)
      skip_build=1
      ;;
    --validate-only)
      validate_only=1
      ;;
    --keep-running)
      keep_running=1
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

if [[ -z "$app_path" ]]; then
  app_path="$derived_data_path/Build/Products/Debug/MilsimPonyGame.app"
fi

require_tool() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required tool: $1" >&2
    exit 1
  fi
}

validate_tools() {
  require_tool xcodebuild
  require_tool open
  require_tool osascript
  require_tool screencapture
  require_tool shasum
  require_tool swift

  if [[ ! -f "$repo_root/Tools/image_diff.swift" ]]; then
    echo "Missing Tools/image_diff.swift" >&2
    exit 1
  fi

  if [[ -n "$baseline_dir" && ! -d "$baseline_dir" ]]; then
    echo "Baseline directory does not exist: $baseline_dir" >&2
    exit 1
  fi
}

build_app() {
  xcodebuild \
    -project "$project_path" \
    -scheme "$scheme_name" \
    -configuration Debug \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    build
}

app_is_running() {
  if [[ -n "$launched_pid" ]]; then
    kill -0 "$launched_pid" >/dev/null 2>&1
  else
    pgrep -x MilsimPonyGame >/dev/null 2>&1
  fi
}

activate_app() {
  if ! open "$app_path"; then
    local executable="$app_path/Contents/MacOS/MilsimPonyGame"
    if [[ ! -x "$executable" ]]; then
      echo "App executable not found: $executable" >&2
      exit 1
    fi
    "$executable" >/tmp/milsim-pony-capture-app.log 2>&1 &
    launched_pid="$!"
    sleep 1
    if ! kill -0 "$launched_pid" >/dev/null 2>&1; then
      echo "App executable exited during capture launch. See /tmp/milsim-pony-capture-app.log" >&2
      exit 1
    fi
  fi

  if [[ -z "$launched_pid" ]]; then
    for _ in {1..20}; do
      if app_is_running; then
        break
      fi
      sleep 0.5
    done
  fi

  osascript <<'APPLESCRIPT'
tell application "MilsimPonyGame" to activate
delay 0.5
tell application "System Events"
  if exists process "MilsimPonyGame" then
    tell process "MilsimPonyGame"
      if exists window 1 then
        set position of window 1 to {80, 80}
        set size of window 1 to {1280, 800}
      end if
    end tell
  end if
end tell
APPLESCRIPT
}

send_key() {
  local key="$1"
  osascript <<APPLESCRIPT
tell application "MilsimPonyGame" to activate
delay 0.2
tell application "System Events" to keystroke "$key"
APPLESCRIPT
}

send_escape() {
  osascript <<'APPLESCRIPT'
tell application "MilsimPonyGame" to activate
delay 0.2
tell application "System Events" to key code 53
APPLESCRIPT
}

capture_step() {
  local name="$1"
  local note="$2"
  local path="$output_dir/${name}.png"
  sleep 0.8
  screencapture -x "$path"
  local sha
  sha="$(shasum -a 256 "$path" | awk '{print $1}')"
  printf '| `%s` | `%s.png` | `%s` | `%s` |\n' "$name" "$name" "$sha" "$note" >>"$output_dir/capture_manifest.md"

  if [[ -n "$baseline_dir" && -f "$baseline_dir/${name}.png" ]]; then
    mkdir -p "$output_dir/diffs"
    local diff_path="$output_dir/diffs/${name}_diff.png"
    local diff_result
    diff_result="$(swift "$repo_root/Tools/image_diff.swift" "$baseline_dir/${name}.png" "$path" "$diff_path" "$diff_threshold")"
    printf '| `%s` | `%s` | `%s` |\n' "$name" "$diff_result" "diffs/${name}_diff.png" >>"$output_dir/diff_manifest.md"
  fi
}

write_manifest_header() {
  mkdir -p "$output_dir"
  cat >"$output_dir/capture_manifest.md" <<EOF
# Cycle ${cycle} Review Captures

- Captured at UTC: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
- App: $app_path
- Derived data: $derived_data_path
- Baseline: ${baseline_dir:-none}
- Diff threshold: $diff_threshold

| Step | File | SHA-256 | Note |
| --- | --- | --- | --- |
EOF

  if [[ -n "$baseline_dir" ]]; then
    cat >"$output_dir/diff_manifest.md" <<EOF
# Cycle ${cycle} Capture Diffs

| Step | Metrics | Diff Image |
| --- | --- | --- |
EOF
  fi
}

main() {
  validate_tools

  if [[ "$validate_only" -eq 1 ]]; then
    mkdir -p "$output_dir"
    printf 'Capture tooling validated. Output root: %s\n' "$output_dir"
    exit 0
  fi

  if [[ "$skip_build" -eq 0 && ! -d "$app_path" ]]; then
    build_app
  elif [[ "$skip_build" -eq 0 && -z "${CAPTURE_REUSE_BUILD:-}" ]]; then
    build_app
  fi

  if [[ ! -d "$app_path" ]]; then
    echo "App bundle not found: $app_path" >&2
    exit 1
  fi

  write_manifest_header
  activate_app

  capture_step "01_title_shell" "Initial title shell before input."
  send_key " "
  capture_step "02_live_route_start" "Fresh live route after briefing confirm."
  send_key "m"
  capture_step "03_overhead_map" "Map view with route, contact lanes, and capture footers."
  send_key "m"
  send_key " "
  capture_step "04_scope_view" "Scoped view for long-range readability comparison."
  send_escape
  capture_step "05_pause_shell" "Pause shell with route-proof and capture guidance."

  if [[ "$keep_running" -eq 0 ]]; then
    osascript -e 'tell application "MilsimPonyGame" to quit' >/dev/null 2>&1 || true
    if [[ -n "$launched_pid" ]]; then
      kill "$launched_pid" >/dev/null 2>&1 || true
    fi
  fi

  printf 'Review captures written to %s\n' "$output_dir"
}

main "$@"
