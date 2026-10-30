# Hako Go SDK

> Part of [**HakoDB**](https://github.com/hakodb/hakodb) — embedded document DB with native vector search and multi-plane sync, written in Rust. The engine + C ABI live in `hakodb/hakodb`; this repo holds the Go SDK.

A complete Go SDK over the HakoDB C-FFI surface, with a fluent document
ergonomic layer. Module: `github.com/hakodb/hakogo`
(package `hako`).

## Features

- Full FFI handle coverage: engine, config, doc, array, query, batch, transaction, watch.
- Complete query/filter/operator coverage available in `hako.Query`.
- Fluent document API:
  - `client.Collection("users").Doc("alice").Set(...)`
  - `Where(...).OrderBy(...).Limit(...).Get()`
  - `Batch().Set(...).Delete(...).Commit()`
  - `RunTransaction(func(tx *hako.Tx) error { ... })`
- Watch callback bridge backed by `hk_engine_watch`.
- Soft delete / retention: deletes are restoreable by default; `Restore`, `RestoreAvailableJSON`, `DeleteQueueJSON`, and `SweepNow` wrap the retention surface, and force deletes are explicit.

## Compatibility

Works against the corresponding core release; each release pairs with a matching `hakodb` tag (see the releases page for the exact pairing).

## Setup — native library

The SDK links the HakoDB cdylib via cgo. Populate `third_party/`
(canonical `hakodb.h` + platform binary) with the sync script:

```powershell
.\sync-core.ps1 -CoreDir C:\Dev\libs\hakodb   # local checkout
.\sync-core.ps1 -Tag <core-release-tag>       # release asset
```

```sh
./sync-core.sh --core-dir /path/to/hakodb
./sync-core.sh --tag <core-release-tag>
```

Binaries under `third_party/lib/` are git-ignored; headers are committed.
`go build`/`go vet` need a C compiler on `PATH` (MinGW gcc on Windows).

## Minimal usage

```go
package main

import (
  "fmt"
  hako "github.com/hakodb/hakogo/hako"
)

func main() {
  db, err := hako.Open("demo.db")
  if err != nil {
    panic(err)
  }
  defer db.Close()
  doc, err := db.GetDoc("users", "alice")
  if err != nil {
    panic(err)
  }
  fmt.Println(doc)
}
```

## Notes

- `go vet` reports four pre-existing `unsafe.Pointer` (cgo.Handle
  bridge) advisories; build is clean.

## Examples

`examples/demo` runs CRUD, query, batch, transaction, and graceful
sync degradation against `third_party/lib` (add it to `PATH` /
`LD_LIBRARY_PATH` first):

```sh
go run ./examples/demo
```
