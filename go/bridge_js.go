// +build js

package gib

// ConnectResult represents the result from a connect operation.
type ConnectResult struct {
    connectionId int
    err error
}

// ConnectionReadResult represents the result from a connection read operation.
type ConnectionReadResult struct {
    data []byte
    err error
}

// ConnectionWriteResult represents the result from a connection write
// operation.
type ConnectionWriteResult struct {
    count int
    err error
}

// ConnectionCloseResult represents the result from a connection close
// operation.
type ConnectionCloseResult struct {
    err error
}

// ListenResult represents the result from a listen operation.
type ListenResult struct {
    listenerId int
    err error
}

// ListenerAcceptResult represents the result from a listener accept operation.
type ListenerAcceptResult struct {
    connectionId int
    err error
}

// ListenerCloseResult represents the result from a listener close operation.
type ListenerCloseResult struct {
    err error
}

// Bridge represents the GopherJS interface to the host environment's connection
// management facilities.  All methods are asynchronous, and the underlying
// method of request/result transport to/from the host is at the discretion of
// the bridge implementation.
type Bridge interface {
	// Connect requests that an IPC connection be made to the specified endpoint
	// (either a socket path or named pipe name).
	Connect(endpoint string) chan ConnectResult

	// ConnectionRead requests that data be read from an IPC connection.  The
	// semantics are those of net.Conn.Read.
	ConnectionRead(connectionId, length int) chan ConnectionReadResult

	// ConnectionRead requests that data be written to an IPC connection.  The
	// semantics are those of net.Conn.Write.
	ConnectionWrite(connectionId int, data []byte) chan ConnectionWriteResult

	// ConnectionClose requests that an IPC connection be closed.  The semantics
	// are those of net.Conn.Close.
	ConnectionClose(connectionId int) chan ConnectionCloseResult

	// Listen requests that an IPC listener be established on the specified
	// endpoint (either a socket path or a named pipe name).
	Listen(endpoint string) chan ListenResult

	// ListenerAccept requests that an IPC listener accept a connection.  The
	// semantics are those of net.Listener.Accept.
	ListenerAccept(listenerId int) chan ListenerAcceptResult

	// ListenerClose requests that an IPC listener be closed.  The semantics
	// are those of net.Listener.Close.
	ListenerClose(listenerId int) chan ListenerCloseResult
}

// Global variables used by the package.
var global struct {
	// The Bridge instance used by the connection/listener API.
	bridge Bridge

	// The control channel used to send the initialization message and shutdown
	// signal
	controlChannel chan string
}

// ClientInitialize starts the IPC bridge initialization sequence, and should be
// invoked on the client (GopherJS) side of things before the corresponding
// HostInitialize function is called.  It returns a channel that will provide a
// single initialization message after bridge initialization is complete and
// will be closed when bridge shutdown begins.
func ClientInitialize() chan string {
	// Create the control channel with a single-item buffer so the
	// HostInitialize function doesn't block
	global.controlChannel = make(chan string, 1)

	// Return the control channel for the client to use
	return global.controlChannel
}

// HostInitialize finishes the IPC bridge initialization sequence by setting the
// global bridge instance and sending the initialization message to the client
// side.  How exactly this function is invoked depends on the host.  Individual
// bridge implementations generally provide a wrapper around this function that
// can be invoked from JavaScript and will create an instance of the bridge
// implementation to pass to this function.
func HostInitialize(bridge Bridge, message string) {
	// Set the global bridge
	global.bridge = bridge

	// Send the initialization message (this will be non-blocking since the
	// control channel is buffered)
	global.controlChannel <- message
}
