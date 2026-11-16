package hako

import (
	"encoding/binary"
	"math"
	"strings"
	"testing"
)

// GraphRAG smoke vs the 0.20.6 native surface: 9-arg v2 (binary stage-1
// ABI), hybrid RRF, pagerank, subgraph.
func TestGraphRAGSurface(t *testing.T) {
	engine, err := Open(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	defer engine.Close()

	// Graph: a -> b -> c via refs.
	if err := engine.CreateTraverseIndex("g"); err != nil {
		t.Fatal(err)
	}
	link := func(id, target string) {
		d := NewDoc()
		defer d.Free()
		if err := d.InsertReference("link", "g", target); err != nil {
			t.Fatal(err)
		}
		if err := engine.Set("g", id, d); err != nil {
			t.Fatal(err)
		}
	}
	link("a", "b")
	link("b", "c")
	c := NewDoc()
	defer c.Free()
	if err := c.InsertInt("v", 1); err != nil {
		t.Fatal(err)
	}
	if err := engine.Set("g", "c", c); err != nil {
		t.Fatal(err)
	}

	sg, err := engine.Subgraph("g", "a", 2, TraverseOutgoing, "", "", "", "", 0)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(sg, `"id":"c"`) {
		t.Fatalf("subgraph missing c: %s", sg)
	}

	rows, err := engine.GraphPagerank("g", nil, TraverseOutgoing, "", "", "", "", 0, 3)
	if err != nil {
		t.Fatal(err)
	}
	if len(rows) != 3 || rows[0].Score < rows[len(rows)-1].Score {
		t.Fatalf("pagerank rows: %v", rows)
	}

	// Hybrid: indexes first, docs second (write-time indexing).
	if err := engine.CreateFTSIndex("docs", "title"); err != nil {
		t.Fatal(err)
	}
	if err := engine.CreateVectorIndexV2("docs", "emb", 2, VectorCosine, 0, 0, 0, true); err != nil {
		t.Fatal(err)
	}
	put := func(id, title string, x, y float32) {
		d := NewDoc()
		defer d.Free()
		if err := d.InsertString("title", title); err != nil {
			t.Fatal(err)
		}
		if err := d.InsertBinary("emb", f32Bytes(x, y)); err != nil {
			t.Fatal(err)
		}
		if err := engine.Set("docs", id, d); err != nil {
			t.Fatal(err)
		}
	}
	put("d1", "red apple", 1.0, 0.0)
	put("d2", "blue sky", 0.0, 1.0)
	put("d3", "red sky", 0.9, 0.1)

	var hits []NearHit
	for i := 0; i < 50; i++ {
		hits, err = engine.HybridSearch("docs", "title", "red", "emb", []float32{1.0, 0.0}, 2, 0)
		if err != nil {
			t.Fatal(err)
		}
		if len(hits) > 0 {
			break
		}
	}
	if err != nil {
		t.Fatal(err)
	}
	for _, h := range hits {
		if h.ID == "d2" {
			t.Fatalf("hybrid returned off-topic d2: %v", hits)
		}
	}
	if len(hits) == 0 {
		t.Fatal("hybrid empty after settle")
	}
}

func f32Bytes(vals ...float32) []byte {
	out := make([]byte, 4*len(vals))
	for i, v := range vals {
		binary.LittleEndian.PutUint32(out[4*i:], math.Float32bits(v))
	}
	return out
}
