#!/usr/bin/env bash
# Populate third_party/ from a core checkout or a release tag asset.
#   ./sync-core.sh --core-dir /path/to/firelite
#   ./sync-core.sh --tag v0.8.20
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/third_party/include" "$ROOT/third_party/lib"

if [[ "${1:-}" == "--core-dir" ]]; then
    CORE="$2"
    cp "$CORE/include/hako.h" "$ROOT/third_party/include/"
    SO="$CORE/target/release/libhakodb.so"
    [[ -f "$SO" ]] || { echo "no release .so at $SO (cargo build --release first)" >&2; exit 1; }
    cp "$SO" "$ROOT/third_party/lib/"
    echo "synced from checkout: $CORE"
elif [[ "${1:-}" == "--tag" ]]; then
    TAG="$2"
    BASE="https://github.com/rizaptk/firelite/releases/download/$TAG"
    curl -sL -o "$ROOT/third_party/include/hako.h" "$BASE/hako.h"
    curl -sL -o "$ROOT/third_party/lib/libhakodb.so" "$BASE/libhakodb-x86_64-unknown-linux-gnu.so"
    echo "synced from release asset: $TAG"
else
    echo "usage: $0 --core-dir DIR | --tag TAG" >&2; exit 1
fi
