#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project_path="$repo_root/MilsimPonyGame.xcodeproj"
scheme_name="MilsimPonyGame"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/MilsimPonyReleaseDerived}"
artifacts_root="${ARTIFACTS_ROOT:-$repo_root/artifacts/release}"
manifest_path="$repo_root/MilsimPonyGame/Assets/WorldData/CanberraBootstrap/world_manifest.json"
release_cycle="${RELEASE_CYCLE:-116}"
expected_version="${EXPECTED_MARKETING_VERSION:-1.16.0}"
expected_build="${EXPECTED_BUILD_NUMBER:-116}"
tester_channel="${TESTER_CHANNEL:-local-review zip}"
notarization_profile="${NOTARIZATION_PROFILE:-}"
validate_only=0
skip_build=0
check_distribution=0
timestamp="$(date -u +"%Y%m%d-%H%M%S")"
release_docs=(
  "README.md"
  "Docs/CYCLE_116_SMOKE_TEST.md"
  "Docs/CYCLE_115_SMOKE_TEST.md"
  "Docs/CYCLE_114_SMOKE_TEST.md"
  "Docs/CYCLE_113_SMOKE_TEST.md"
  "Docs/CYCLE_112_SMOKE_TEST.md"
  "Docs/CYCLE_112_TEXTURE_ACCEPTANCE.md"
  "Docs/CYCLE_111_SMOKE_TEST.md"
  "Docs/CYCLE_110_SMOKE_TEST.md"
  "Docs/CYCLE_109_SMOKE_TEST.md"
  "Docs/CYCLE_108_SMOKE_TEST.md"
  "Docs/CYCLE_107_SMOKE_TEST.md"
  "Docs/CYCLE_106_SMOKE_TEST.md"
  "Docs/CYCLE_105_SMOKE_TEST.md"
  "Docs/CYCLE_104_SMOKE_TEST.md"
  "Docs/CYCLE_103_SMOKE_TEST.md"
  "Docs/CYCLE_102_SMOKE_TEST.md"
  "Docs/CYCLE_101_SMOKE_TEST.md"
  "Docs/CYCLE_100_SMOKE_TEST.md"
  "Docs/CYCLE_99_SMOKE_TEST.md"
  "Docs/LIGHTING_ARCHITECTURE_DECISION.md"
  "Docs/TESTER_DISTRIBUTION_PIPELINE.md"
  "Docs/DEVELOPMENT_BACKLOG.md"
)

usage() {
  cat <<EOF
Usage: Tools/package_release.sh [--validate-only] [--check-distribution] [--skip-build]

  --validate-only       Validate version policy, world manifest, and release docs without building.
  --check-distribution  Validate tester handoff inputs and report notarization readiness.
  --skip-build          Package an already-built Release app from DERIVED_DATA_PATH.
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
    --check-distribution)
      check_distribution=1
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

build_app() {
  xcodebuild \
    -project "$project_path" \
    -scheme "$scheme_name" \
    -configuration Release \
    -derivedDataPath "$derived_data_path" \
    CODE_SIGNING_ALLOWED=NO \
    build
}

read_plist_value() {
  local plist_path="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :$key" "$plist_path"
}

git_commit() {
  git -C "$repo_root" rev-parse --short HEAD 2>/dev/null || echo "unavailable"
}

git_tree_state() {
  if git -C "$repo_root" diff --quiet --ignore-submodules HEAD -- 2>/dev/null; then
    echo "clean"
  else
    echo "dirty"
  fi
}

project_setting() {
  local key="$1"
  sed -n "s/^[[:space:]]*${key} = \\([^;]*\\);/\\1/p" "$repo_root/MilsimPonyGame.xcodeproj/project.pbxproj" | head -n 1
}

plist_json_value() {
  local plist_path="$1"
  local key_path="$2"
  plutil -extract "$key_path" raw -o - "$plist_path"
}

validate_json_file() {
  local json_path="$1"
  if [[ ! -f "$json_path" ]]; then
    echo "Missing JSON file: $json_path" >&2
    exit 1
  fi
  jq empty "$json_path" >/dev/null
}

validate_release_inputs() {
  local project_version
  local project_build
  local package_root
  local coordinate_file
  local scene_file
  local sector_index
  local sector_file

  project_version="$(project_setting MARKETING_VERSION)"
  project_build="$(project_setting CURRENT_PROJECT_VERSION)"

  if [[ "$project_version" != "$expected_version" ]]; then
    echo "Expected MARKETING_VERSION $expected_version but found $project_version" >&2
    exit 1
  fi

  if [[ "$project_build" != "$expected_build" ]]; then
    echo "Expected CURRENT_PROJECT_VERSION $expected_build but found $project_build" >&2
    exit 1
  fi

  validate_json_file "$manifest_path"
  package_root="$(dirname "$manifest_path")"
  coordinate_file="$(plist_json_value "$manifest_path" coordinateSystemFile)"
  scene_file="$(plist_json_value "$manifest_path" sceneFile)"
  validate_json_file "$package_root/$coordinate_file"
  validate_json_file "$package_root/$scene_file"

  sector_index=0
  while sector_file="$(plist_json_value "$manifest_path" "sectorFiles.$sector_index" 2>/dev/null)"; do
    validate_json_file "$package_root/$sector_file"
    sector_index=$((sector_index + 1))
  done

  if [[ "$sector_index" -eq 0 ]]; then
    echo "World manifest has no sector files" >&2
    exit 1
  fi

  for doc_path in "${release_docs[@]}"; do
    if [[ ! -f "$repo_root/$doc_path" ]]; then
      echo "Missing release document: $doc_path" >&2
      exit 1
    fi
  done

  printf 'Release inputs validated: v%s build %s / %d sectors / cycle %s docs\n' \
    "$project_version" "$project_build" "$sector_index" "$release_cycle"
}

check_distribution_inputs() {
  validate_release_inputs

  local archive_pattern="MilsimPonyGame-v${expected_version}-b${expected_build}-cycle${release_cycle}-<utc>.zip"
  local notary_status="notarytool unavailable"

  if command -v xcrun >/dev/null 2>&1 && xcrun notarytool --help >/dev/null 2>&1; then
    if [[ -n "$notarization_profile" ]]; then
      notary_status="notarytool available / profile $notarization_profile configured by environment"
    else
      notary_status="notarytool available / NOTARIZATION_PROFILE not set"
    fi
  fi

  printf 'Tester distribution check:\n'
  printf '  Channel:        %s\n' "$tester_channel"
  printf '  Archive:        %s\n' "$archive_pattern"
  printf '  Tester guide:   Docs/TESTER_DISTRIBUTION_PIPELINE.md\n'
  printf '  Notarization:   %s\n' "$notary_status"
  printf '  CI gate:        Tools/package_release.sh --validate-only && Tools/package_release.sh --check-distribution\n'
  printf '  SDF UI scope:   HUD/map text crispness scoped after tester pipeline\n'
  printf '  Lighting gate:  Docs/LIGHTING_ARCHITECTURE_DECISION.md\n'
}

write_manifest() {
  local manifest_path="$1"
  local version="$2"
  local build_number="$3"
  local bundle_identifier="$4"
  local packaged_at="$5"

  cat >"$manifest_path" <<EOF
Product: MilsimPonyGame
Version: $version
Build: $build_number
Bundle Identifier: $bundle_identifier
Packaged At UTC: $packaged_at
Git Commit: $(git_commit)
Git Tree: $(git_tree_state)
Derived Data Path: $derived_data_path
Included App: MilsimPonyGame.app
Release Cycle: $release_cycle
Version Policy: marketing $expected_version with cycle build $expected_build
Archive Pattern: MilsimPonyGame-v${version}-b${build_number}-cycle${release_cycle}-${timestamp}
World Manifest: MilsimPonyGame/Assets/WorldData/CanberraBootstrap/world_manifest.json
Tester Channel: $tester_channel
Notarization Profile: ${notarization_profile:-not configured}
Distribution Gate: Tools/package_release.sh --check-distribution
SDF UI Scope: HUD, scope, and map labels use scalable outlined text
Lighting Architecture: Docs/LIGHTING_ARCHITECTURE_DECISION.md
Included Docs:
- ReleaseDocs/README.md
- ReleaseDocs/CYCLE_116_SMOKE_TEST.md
- ReleaseDocs/CYCLE_115_SMOKE_TEST.md
- ReleaseDocs/CYCLE_114_SMOKE_TEST.md
- ReleaseDocs/CYCLE_113_SMOKE_TEST.md
- ReleaseDocs/CYCLE_112_SMOKE_TEST.md
- ReleaseDocs/CYCLE_112_TEXTURE_ACCEPTANCE.md
- ReleaseDocs/CYCLE_111_SMOKE_TEST.md
- ReleaseDocs/CYCLE_110_SMOKE_TEST.md
- ReleaseDocs/CYCLE_109_SMOKE_TEST.md
- ReleaseDocs/CYCLE_108_SMOKE_TEST.md
- ReleaseDocs/CYCLE_107_SMOKE_TEST.md
- ReleaseDocs/CYCLE_106_SMOKE_TEST.md
- ReleaseDocs/CYCLE_105_SMOKE_TEST.md
- ReleaseDocs/CYCLE_104_SMOKE_TEST.md
- ReleaseDocs/CYCLE_103_SMOKE_TEST.md
- ReleaseDocs/CYCLE_102_SMOKE_TEST.md
- ReleaseDocs/CYCLE_101_SMOKE_TEST.md
- ReleaseDocs/CYCLE_100_SMOKE_TEST.md
- ReleaseDocs/CYCLE_99_SMOKE_TEST.md
- ReleaseDocs/LIGHTING_ARCHITECTURE_DECISION.md
- ReleaseDocs/TESTER_DISTRIBUTION_PIPELINE.md
- ReleaseDocs/DEVELOPMENT_BACKLOG.md
EOF
}

main() {
  local app_path
  local info_plist
  local version
  local build_number
  local bundle_identifier
  local package_name
  local package_dir
  local docs_dir
  local zip_path
  local packaged_at

  mkdir -p "$artifacts_root"

  if [[ "$check_distribution" -eq 1 ]]; then
    check_distribution_inputs
    exit 0
  fi

  validate_release_inputs

  if [[ "$validate_only" -eq 1 ]]; then
    exit 0
  fi

  if [[ "$skip_build" -eq 0 ]]; then
    build_app
  fi

  app_path="$derived_data_path/Build/Products/Release/MilsimPonyGame.app"
  info_plist="$app_path/Contents/Info.plist"

  if [[ ! -f "$info_plist" ]]; then
    echo "Release Info.plist not found at $info_plist" >&2
    exit 1
  fi

  if [[ ! -x "$app_path/Contents/MacOS/MilsimPonyGame" ]]; then
    echo "Release executable not found at $app_path/Contents/MacOS/MilsimPonyGame" >&2
    exit 1
  fi

  version="$(read_plist_value "$info_plist" CFBundleShortVersionString)"
  build_number="$(read_plist_value "$info_plist" CFBundleVersion)"
  bundle_identifier="$(read_plist_value "$info_plist" CFBundleIdentifier)"

  if [[ "$version" != "$expected_version" || "$build_number" != "$expected_build" ]]; then
    echo "Built app version $version ($build_number) does not match expected $expected_version ($expected_build)" >&2
    exit 1
  fi

  package_name="MilsimPonyGame-v${version}-b${build_number}-cycle${release_cycle}-${timestamp}"
  package_dir="$artifacts_root/$package_name"
  docs_dir="$package_dir/ReleaseDocs"
  zip_path="$package_dir.zip"
  packaged_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  mkdir -p "$docs_dir"
  ditto "$app_path" "$package_dir/MilsimPonyGame.app"
  for doc_path in "${release_docs[@]}"; do
    cp "$repo_root/$doc_path" "$docs_dir/"
  done
  write_manifest "$package_dir/build_manifest.txt" "$version" "$build_number" "$bundle_identifier" "$packaged_at"
  ditto -c -k --keepParent "$package_dir" "$zip_path"

  if [[ ! -d "$package_dir/MilsimPonyGame.app" || ! -x "$package_dir/MilsimPonyGame.app/Contents/MacOS/MilsimPonyGame" || ! -f "$package_dir/build_manifest.txt" || ! -f "$zip_path" ]]; then
    echo "Package smoke check failed for $package_dir" >&2
    exit 1
  fi

  printf 'Release package created:\n'
  printf '  App bundle: %s\n' "$package_dir/MilsimPonyGame.app"
  printf '  Manifest:   %s\n' "$package_dir/build_manifest.txt"
  printf '  Zip:        %s\n' "$zip_path"
}

main "$@"
