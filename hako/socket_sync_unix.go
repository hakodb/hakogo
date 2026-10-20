//go:build unix

package hako

/*
#cgo CFLAGS: -I${SRCDIR}/../third_party/include
#cgo LDFLAGS: -L${SRCDIR}/../third_party/lib -lhakodb
#include "hakodb.h"
*/
import "C"

import "fmt"

// SocketSync is the Unix-domain-socket sync plane (not built on Windows:
// the core exports hk_socket_sync_* only under cfg(unix)).
type SocketSync struct{ ptr *C.HK_SocketSync }

// NewSocketSync creates a Unix-domain-socket sync endpoint.
func (e *Engine) NewSocketSync() (*SocketSync, error) {
	ptr := C.hk_socket_sync_new(e.ptr)
	if ptr == nil {
		return nil, fmt.Errorf("hk_socket_sync_new failed: %s", lastError())
	}
	return &SocketSync{ptr: ptr}, nil
}

// Serve listens on path; the call returns once the listener is stopped.
func (s *SocketSync) Serve(path string) error {
	cp, free := cString(path)
	defer free()
	return checkStatus("hk_socket_sync_serve", C.hk_socket_sync_serve(s.ptr, cp))
}

// Dial connects to a peer listening on path.
func (s *SocketSync) Dial(path string) error {
	cp, free := cString(path)
	defer free()
	return checkStatus("hk_socket_sync_dial", C.hk_socket_sync_dial(s.ptr, cp))
}

func (s *SocketSync) Status() (string, error) {
	return ownedCStringJSON(func() *C.char { return C.hk_socket_sync_status(s.ptr) })
}

func (s *SocketSync) Free() {
	if s != nil && s.ptr != nil {
		C.hk_socket_sync_free(s.ptr)
		s.ptr = nil
	}
}
