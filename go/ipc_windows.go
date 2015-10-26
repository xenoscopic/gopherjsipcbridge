package gib

// System imports
import "net"

// npipe imports
import "gopkg.in/natefinch/npipe.v2"

// DialIPC establishes a new IPC connection.  On Windows systems, this is done
// using named pipes, and the path argument should be the name of an existing
// named pipe endpoint to connect to.
func DialIPC(path string) (net.Conn, error) {
	return npipe.Dial(path)
}

// ListenIPC establishes a new IPC connection listener.  On Windows systems,
// this is done using named pipes, and the path argument should be the name of
// a named pipe at which to create the endpoint.  The name should not be bound
// to an existing listener.
func ListenIPC(path string) (net.Listener, error) {
	return npipe.Listen(path)
}
