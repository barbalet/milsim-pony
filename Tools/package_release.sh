#!/bin/bash

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
project_path="$repo_root/MilsimPonyGame.xcodeproj"
scheme_name="MilsimPonyGame"
derived_data_path="${DERIVED_DATA_PATH:-/tmp/MilsimPonyReleaseDerived}"
artifacts_root="${ARTIFACTS_ROOT:-$repo_root/artifacts/release}"
timestamp="$(date -u +"%Y%m%d-%H%M%S")"

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
Included Docs:
- ReleaseDocs/CYCLE_9_SMOKE_TEST.md
- ReleaseDocs/CYCLE_9_RELEASE_CHECKLIST.md
- ReleaseDocs/CYCLE_9_RELEASE_NOTES.md
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
  build_app

  app_path="$derived_data_path/Build/Products/Release/MilsimPonyGame.app"
  info_plist="$app_path/Contents/Info.plist"

  if [[ ! -f "$info_plist" ]]; then
    echo "Release Info.plist not found at $info_plist" >&2
    exit 1
  fi

  version="$(read_plist_value "$info_plist" CFBundleShortVersionString)"
  build_number="$(read_plist_value "$info_plist" CFBundleVersion)"
  bundle_identifier="$(read_plist_value "$info_plist" CFBundleIdentifier)"

  package_name="MilsimPonyGame-v${version}-b${build_number}-${timestamp}"
  package_dir="$artifacts_root/$package_name"
  docs_dir="$package_dir/ReleaseDocs"
  zip_path="$package_dir.zip"
  packaged_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  mkdir -p "$docs_dir"
  ditto "$app_path" "$package_dir/MilsimPonyGame.app"
  cp "$repo_root/Docs/CYCLE_9_SMOKE_TEST.md" "$docs_dir/"
  cp "$repo_root/Docs/CYCLE_9_RELEASE_CHECKLIST.md" "$docs_dir/"
  cp "$repo_root/Docs/CYCLE_9_RELEASE_NOTES.md" "$docs_dir/"
  write_manifest "$package_dir/build_manifest.txt" "$version" "$build_number" "$bundle_identifier" "$packaged_at"
  ditto -c -k --keepParent "$package_dir" "$zip_path"

  printf 'Release package created:\n'
  printf '  App bundle: %s\n' "$package_dir/MilsimPonyGame.app"
  printf '  Manifest:   %s\n' "$package_dir/build_manifest.txt"
  printf '  Zip:        %s\n' "$zip_path"
}

main "$@"
