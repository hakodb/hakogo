package hako

import (
	"strings"
	"testing"
)

// Soft-delete smoke vs the 0.20.0 native surface: soft delete retains a
// record, restore consumes it, force retains nothing.
func TestSoftDeleteRestoreRoundtrip(t *testing.T) {
	engine, err := Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer engine.Close()

	alice := NewDoc()
	alice.InsertInt("age", 32)
	if err := engine.Set("users", "u1", alice); err != nil {
		t.Fatal(err)
	}
	alice.Free()

	if err := engine.Delete("users", "u1"); err != nil {
		t.Fatal(err)
	}
	if got, _ := engine.GetDoc("users", "u1"); got != nil {
		t.Fatal("deleted doc must be invisible")
	}

	avail, err := engine.RestoreAvailableJSON("")
	if err != nil || !strings.Contains(avail, `"col":"users"`) {
		t.Fatalf("restore_available: %q err=%v", avail, err)
	}
	if err := engine.Restore("users", "u1"); err != nil {
		t.Fatal(err)
	}
	got, err := engine.GetDoc("users", "u1")
	if err != nil || got == nil {
		t.Fatal("restore should bring the doc back")
	}
	got.Free()
	if avail, _ = engine.RestoreAvailableJSON(""); avail != "[]" {
		t.Fatalf("record should be consumed, got %q", avail)
	}

	// Force parity: legacy shape retains nothing.
	b := NewDoc()
	b.InsertInt("age", 1)
	if err := engine.Set("users", "u2", b); err != nil {
		t.Fatal(err)
	}
	b.Free()
	if err := engine.DeleteForce("users", "u2"); err != nil {
		t.Fatal(err)
	}
	if avail, _ = engine.RestoreAvailableJSON(""); avail != "[]" {
		t.Fatalf("force delete must not retain, got %q", avail)
	}
}
