#!/usr/bin/env bash
# Populate third_party/ from a core checkout or a release tag asset.
#   ./sync-core.sh --core-dir /path/to/hakodb
#   ./sync-core.sh --tag v0.9.0
#   ./sync-core.sh --tag v0.9.0 --lib-tag linux-glibc2.35-ubuntu22
# Linux .so default: el8 build (runs on glibc >= 2.28 everywhere).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/third_party/include" "$ROOT/third_party/lib"
LIBTAG="${LIBTAG:-linux-glibc2.28-el8}"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --lib-tag) LIBTAG="$2"; shift 2;;
        *) break;;
    esac
done

if [[ "${1:-}" == "--core-dir" ]]; then
    CORE="$2"
    HDR="$CORE/target/release/hakodb.h"
    [[ -f "$HDR" ]] || { echo "no generated header at $HDR (cargo build --release first)" >&2; exit 1; }
    cp "$HDR" "$ROOT/third_party/include/"
    SO="$CORE/target/release/libhakodb.so"
    [[ -f "$SO" ]] || { echo "no release .so at $SO (cargo build --release first)" >&2; exit 1; }
    cp "$SO" "$ROOT/third_party/lib/"
    echo "synced from checkout: $CORE"
elif [[ "${1:-}" == "--tag" ]]; then
    TAG="$2"
    BASE="https://github.com/hakodb/hakodb/releases/download/$TAG"
    curl -sL -o "$ROOT/third_party/include/hakodb.h" "$BASE/hakodb.h"
    curl -sL -o "$ROOT/third_party/lib/libhakodb.so" "$BASE/libhakodb-x86_64-unknown-$LIBTAG.so"
    echo "synced from release asset: $TAG ($LIBTAG)"
else
    echo "usage: $0 --core-dir DIR | --tag TAG" >&2; exit 1
fi
