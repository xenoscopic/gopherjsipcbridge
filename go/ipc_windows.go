// +build windows,!js

package ipc

// System imports
import "net"

// npipe imports
import "gopkg.in/natefinch/npipe.v2"

// DialIPC establishes a new IPC connection.  On Windows systems, this is done
// using named pipes, and the endpoint argument should be the name of an
// existing named pipe endpoint to connect to.
func DialIPC(endpoint string) (net.Conn, error) {
	return npipe.Dial(endpoint)
}

// ListenIPC establishes a new IPC connection listener.  On Windows systems,
// this is done using named pipes, and the endpoint argument should be the name
// of a named pipe at which to create the endpoint.  The name should not be
// bound to an existing listener.
func ListenIPC(endpoint string) (net.Listener, error) {
	return npipe.Listen(endpoint)
}
