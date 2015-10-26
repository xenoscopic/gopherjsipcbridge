// +build !windows,!js

package gib

// System imports
import "net"

// DialIPC establishes a new IPC connection.  On POSIX systems, this is done
// using Unix domain sockets, and the path argument should be the path of an
// existing Unix domain socket endpoint to connect to.
func DialIPC(path string) (net.Conn, error) {
	return net.Dial("unix", path)
}

// ListenIPC establishes a new IPC connection listener.  On POSIX systems, this
// is done using Unix domain sockets, and the path argument should be the path
// at which to create the endpoint.  The path should not be bound to an existing
// listener.
func ListenIPC(path string) (net.Listener, error) {
	return net.Listen("unix", path)
}
