// +build js

package ipc

// System imports
import (
	"net"
	"time"
	"errors"
)

// ipcAddr implements the net.Addr interface for GopherJS IPC connections.
type ipcAddr struct {
	endpoint string
}

func (*ipcAddr) Network() string {
	return "ipc";
}

func (a *ipcAddr) String() string {
	return a.endpoint
}

// ipcConn implements the net.Conn interface for GopherJS IPC connections.
type ipcConn struct {
	address *ipcAddr
	connectionId int
}

func (c *ipcConn) Read(b []byte) (int, error) {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.ConnectionRead(c.connectionId, len(b))

	// Wait for the result
	result := <-resultChannel

	// We always copy the resultant bytes, regardless of errors
	copy(b, result.data)

	// All done
	return len(result.data), result.err
}

func (c *ipcConn) Write(b []byte) (int, error) {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.ConnectionWrite(c.connectionId, b)

	// Wait for the result
	result := <-resultChannel

	// All done
	return result.count, result.err
}

func (c *ipcConn) Close() error {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.ConnectionClose(c.connectionId)

	// Wait for the result
	result := <-resultChannel

	// All done
	return result.err
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
// done using Unix domain sockets, and the endpoint argument should be the path
// of an existing Unix domain socket endpoint to connect to.  On Windows
// systems, this is done using named pipes, and the endpoint argument should be
// the name of an existing named pipe endpoint to connect to.
func DialIPC(endpoint string) (net.Conn, error) {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.Connect(endpoint)

	// Wait for the result
	result := <-resultChannel

	// Watch for errors
	if result.err != nil {
		return nil, result.err
	}

	// All done
	return &ipcConn{
		address: &ipcAddr{endpoint: endpoint},
		connectionId: result.connectionId,
	}, nil
}

// ipcConn implements the net.Listener interface for GopherJS IPC connections.
type ipcListener struct {
	address *ipcAddr
	listenerId int
}

func (l *ipcListener) Accept() (net.Conn, error) {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.ListenerAccept(l.listenerId)

	// Wait for the result
	result := <-resultChannel

	// Watch for errors
	if result.err != nil {
		return nil, result.err
	}

	// All done
	return &ipcConn{
		address: l.address,
		connectionId: result.connectionId,
	}, nil
}

func (l *ipcListener) Close() error {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.ConnectionClose(l.listenerId)

	// Wait for the result
	result := <-resultChannel

	// All done
	return result.err
}

func (l *ipcListener) Addr() net.Addr {
	return l.address
}

// ListenIPC establishes a new IPC connection listener.  On POSIX systems, this
// is done using Unix domain sockets, and the endpoint argument should be the
// path at which to create the endpoint.  The path should not be bound to an
// existing listener.  On Windows systems, this is done using named pipes, and
// the endpoint argument should be the name of a named pipe at which to create
// the endpoint.  The name should not be bound to an existing listener.
func ListenIPC(endpoint string) (net.Listener, error) {
	// Dispatch the request through the bridge
	resultChannel := global.bridge.Listen(endpoint)

	// Wait for the result
	result := <-resultChannel

	// Watch for errors
	if result.err != nil {
		return nil, result.err
	}

	// All done
	return &ipcListener{
		address: &ipcAddr{endpoint: endpoint},
		listenerId: result.listenerId,
	}, nil
}
