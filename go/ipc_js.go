// +build js

package gib

// System imports
import (
	"net"
	"time"
	"errors"
)

// ipcAddr implements the net.Addr interface for GopherJS IPC connections.
type ipcAddr struct {
	path string
}

func (*ipcAddr) Network() string {
	return "ipc";
}

func (a *ipcAddr) String() string {
	return a.path
}

// ipcConn implements the net.Conn interface for GopherJS IPC connections.
type ipcConn struct {
	address *ipcAddr
	connectionId int
}

func (c *ipcConn) Read(b []byte) (int, error) {
	// Read through the bridge
	buffer, err := bridge.connectionRead(c.connectionId, len(b))

	// We always copy the resultant bytes, regardless of errors
	copy(b, buffer)

	// All done
	return len(buffer), err
}

func (c *ipcConn) Write(b []byte) (int, error) {
	// Write through the bridge
	return bridge.connectionWrite(c.connectionId, b)
}

func (c *ipcConn) Close() error {
	// Close through the bridge
	return bridge.connectionClose(c.connectionId)
}

func (c *ipcConn) LocalAddr() net.Addr {
	return c.address
}

func (c *ipcConn) RemoteAddr() net.Addr {
	return c.address
}

func (c *ipcConn) SetDeadline(t time.Time) error {
	return errors.New("read/write deadlines not supported")
}

func (c *ipcConn) SetReadDeadline(t time.Time) error {
	// TODO: On POSIX, we can implement this using SO_RCVTIMEO, but the CLR API
	// doesn't support ReadTimeout for NamedPipe(Client|Server)Stream.  It's
	// also not clear how we'd implement this precisely since it's done as an
	// absolute time instead of a relative one.  Perhaps we can implement this
	// from the GopherJS side?  Should check the GopherJS websocket deadline
	// implementation.
	return errors.New("read deadlines not supported")
}

func (c *ipcConn) SetWriteDeadline(t time.Time) error {
	// TODO: On POSIX, we can implement this using SO_SNDTIMEO, but the CLR API
	// doesn't support WriteTimeout for NamedPipe(Client|Server)Stream.  It's
	// also not clear how we'd implement this precisely since it's done as an
	// absolute time instead of a relative one.  Perhaps we can implement this
	// from the GopherJS side?  Should check the GopherJS websocket deadline
	// implementation.
	return errors.New("write deadlines not supported")
}

// DialIPC establishes a new GopherJS IPC connection.  On POSIX systems, this is
// done using Unix domain sockets, and the path argument should be the path of
// an existing Unix domain socket endpoint to connect to.  On Windows systems,
// this is done using named pipes, and the path argument should be the name of
// an existing named pipe endpoint to connect to.
func DialIPC(path string) (net.Conn, error) {
	// Connect through the bridge
	connectionId, err := bridge.connect(path)
	if err != nil {
		return nil, err
	}

	// All done
	return &ipcConn{
		address: &ipcAddr{path: path},
		connectionId: connectionId,
	}, nil
}

// ipcConn implements the net.Listener interface for GopherJS IPC connections.
type ipcListener struct {
	address *ipcAddr
	listenerId int
}

func (l *ipcListener) Accept() (net.Conn, error) {
	// Accept over the bridge
	connectionId, err := bridge.listenerAccept(l.listenerId)
	if err != nil {
		return nil, err
	}

	// All done
	return &ipcConn{address: l.address, connectionId: connectionId}, nil
}

func (l *ipcListener) Close() error {
	// Close through the bridge
	return bridge.listenerClose(l.listenerId)
}

func (l *ipcListener) Addr() net.Addr {
	return l.address
}

// ListenIPC establishes a new IPC connection listener.  On POSIX systems, this
// is done using Unix domain sockets, and the path argument should be the path
// at which to create the endpoint.  The path should not be bound to an existing
// listener.  On Windows systems, this is done using named pipes, and the path
// argument should be the name of a named pipe at which to create the endpoint.
// The name should not be bound to an existing listener.
func ListenIPC(path string) (net.Listener, error) {
	// Listen through the bridge
	listenerId, err := bridge.listen(path)
	if err != nil {
		return nil, err
	}

	// All done
	return &ipcListener{
		address: &ipcAddr{path: path},
		listenerId: listenerId,
	}, nil
}
