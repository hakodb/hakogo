# FireLite Go SDK (v0.1.1)

A complete Go SDK over the FireLite C-FFI surface, with a Firestore-style
ergonomic layer. Module: `github.com/firelite-db/firelite-go`.

## Features

- Full FFI handle coverage: engine, config, doc, array, query, batch, transaction, watch.
- Complete query/filter/operator coverage available in `firelite.Query`.
- Firestore-style fluent API:
  - `client.Collection("users").Doc("alice").Set(...)`
  - `Where(...).OrderBy(...).Limit(...).Get()`
  - `Batch().Set(...).Delete(...).Commit()`
  - `RunTransaction(func(tx *firelite.Tx) error { ... })`
- Watch callback bridge backed by `fl_engine_watch`.

## Compatibility

| firelite-go | firelite core |
|---|---|
| 0.1.1 | `cloud_sync` branch / `v0.8.20`+ release asset |

## Setup — native library

The SDK links the FireLite cdylib via cgo. Populate `third_party/`
(canonical `firelite.h` + platform binary) with the sync script:

```powershell
.\sync-core.ps1 -CoreDir C:\Dev\libs\firelite   # local checkout
.\sync-core.ps1 -Tag v0.8.20                     # release asset
```

```sh
./sync-core.sh --core-dir /path/to/firelite
./sync-core.sh --tag v0.8.20
```

Binaries under `third_party/lib/` are git-ignored; headers are committed.
`go build`/`go vet` need a C compiler on `PATH` (MinGW gcc on Windows).

## Minimal usage

```go
package main

import (
  "fmt"
  firelite "github.com/firelite-db/firelite-go/firelite"
)

func main() {
  db, err := firelite.Open("demo.db")
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

- `go vet` reports three pre-existing `unsafe.Pointer` (cgo.Handle
  bridge) advisories; build is clean.

## Examples

`examples/demo` runs CRUD, query, batch, transaction, and graceful
sync degradation against `third_party/lib` (add it to `PATH` /
`LD_LIBRARY_PATH` first):

```sh
go run ./examples/demo
```
