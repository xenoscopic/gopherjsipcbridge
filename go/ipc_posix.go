// +build !windows,!js

package ipc

// System imports
import "net"

// DialIPC establishes a new IPC connection.  On POSIX systems, this is done
// using Unix domain sockets, and the endpoint argument should be the path of an
// existing Unix domain socket endpoint to connect to.
func DialIPC(endpoint string) (net.Conn, error) {
	return net.Dial("unix", endpoint)
}

// ListenIPC establishes a new IPC connection listener.  On POSIX systems, this
// is done using Unix domain sockets, and the endpoint argument should be the
// path at which to create the endpoint.  The path should not be bound to an
// existing listener.
func ListenIPC(endpoint string) (net.Listener, error) {
	return net.Listen("unix", endpoint)
}
