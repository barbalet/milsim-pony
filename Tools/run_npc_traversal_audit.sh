#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
module_cache_path="${CLANG_MODULE_CACHE_PATH:-/tmp/codex-clang-modules}"
object_path="${OBJECT_PATH:-/tmp/GameCore.npc_audit.o}"
tool_path="${TOOL_PATH:-/tmp/npc_traversal_audit}"

mkdir -p "$module_cache_path"

clang -std=c11 -Wall -Wextra -pedantic \
    -I "$repo_root/MilsimPonyGame/Core/include" \
    -c "$repo_root/MilsimPonyGame/Core/GameCore.c" \
    -o "$object_path"

CLANG_MODULE_CACHE_PATH="$module_cache_path" \
swiftc \
    -import-objc-header "$repo_root/MilsimPonyGame/Support/MilsimPonyGame-Bridging-Header.h" \
    "$repo_root/MilsimPonyGame/World/WorldSceneData.swift" \
    "$repo_root/MilsimPonyGame/World/WorldBootstrap.swift" \
    "$repo_root/Tools/npc_traversal_audit.swift" \
    "$object_path" \
    -o "$tool_path"

CLANG_MODULE_CACHE_PATH="$module_cache_path" "$tool_path" "$@"
