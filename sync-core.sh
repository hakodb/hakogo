#!/usr/bin/env bash
# Populate third_party/ from a core checkout or a release tag asset.
#   ./sync-core.sh --core-dir /path/to/firelite
#   ./sync-core.sh --tag v0.8.20
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/third_party/include" "$ROOT/third_party/lib"

if [[ "${1:-}" == "--core-dir" ]]; then
    CORE="$2"
    cp "$CORE/include/firelite.h" "$ROOT/third_party/include/"
    SO="$CORE/target/release/libfirelite.so"
    [[ -f "$SO" ]] || { echo "no release .so at $SO (cargo build --release first)" >&2; exit 1; }
    cp "$SO" "$ROOT/third_party/lib/"
    echo "synced from checkout: $CORE"
elif [[ "${1:-}" == "--tag" ]]; then
    TAG="$2"
    curl -sL -o /tmp/firelite-rel.tar.gz \
      "https://github.com/rizaptk/firelite/releases/download/$TAG/firelite-$TAG-x86_64-unknown-linux-gnu.tar.gz"
    mkdir -p /tmp/firelite-rel && tar -xzf /tmp/firelite-rel.tar.gz -C /tmp/firelite-rel
    cp /tmp/firelite-rel/firelite.h "$ROOT/third_party/include/"
    cp /tmp/firelite-rel/libfirelite.so "$ROOT/third_party/lib/"
    echo "synced from release asset: $TAG"
else
    echo "usage: $0 --core-dir DIR | --tag TAG" >&2; exit 1
fi
