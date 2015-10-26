// +build js

package gib

// System imports
import (
	"errors"
	"encoding/base64"
)

// GopherJS imports
import (
    "github.com/gopherjs/gopherjs/js"
    sync "github.com/gopherjs/gopherjs/nosync"
)

// Main bridge type which coordinates access between the host and GopherJS
// TODO: Can this type be private and still have JS-visible methods?
type Bridge struct {
	// Control channel to allow the host to send messages to GopherJS code
	controlChannel chan string

	// Request handlers.  These will be set by the host environment.  If any are
	// left nil, the GopherJS IPC Bridge operations depending on these request
	// handlers will return an error saying that the operation is unsupported.

	// Handler for connect requests.  The first argument will be the sequence
	// and the second argument will be a base64-encoded set of bytes
	// representing the UTF-8 string of the path to connect to.
	connectHandler func(int, string)

	// Handler for connection read requests.  The first argument will be the
	// sequence, the second argument will be the connection id, and the third
	// argument will be the requested read size.
	connectionReadHandler func(int, int, int)

	// Handler for connection write requests.  The first argument will be the
	// sequence, the second argument will be the connection id, and the third
	// argument will be a base64-encoded string representing the bytes to send.
	connectionWriteHandler func(int, int, string)

	// Handler for connection close requests.  The first argument will be the
	// sequence and the second argument will be the connection id.
	connectionCloseHandler func(int, int)

	// Handler for listen requests.  The first argument will be the sequence
	// and the second argument will be a base64-encoded set of bytes
	// representing the UTF-8 string of the path to listen on.
	listenHandler func(int, string)

	// Handler for listener accept requests.  The first argument will be the
	// sequence and the second argument will be the listener id.
	listenerAcceptHandler func(int, int)

	// Handler for listener close requests. The first argument will be the
	// sequence and the second argument will be the listener id.
	listenerCloseHandler func(int, int)

	// Function to convert a sequence of bytes to a base64 encoding.  This
	// function will be set by the initialization function to the fastest
	// implementation available.
	base64EncodeBytes func([]byte) string

	// Function to decode a set of base64-encoded bytes.  This function will be
	// set by the initialization function to the fastest implementation
	// available.
	base64DecodeBytes func(string) []byte

	// Function to convert a UTF-8 string to a base64-encoded set of bytes
	// representing the string's UTF-8 bytes.  This function will be set by the
	// initialization function to the fastest implementation available.
	base64EncodeString func(string) string

	// Function to decode a set of base64-encoded bytes into (what are assumed
	// to be) a set of bytes representing a UTF-8 string, and then generate a
	// string from those bytes.  This function will be set by the initialization
	// function to the fastest implementation available.
	base64DecodeString func(string) string

	// Sequence lock.  Technically not necessary for GopherJS, but better for
	// portability.
	sequenceLock sync.Mutex

	// Next sequence value
	nextSequence int
	
	// Maps sequences to response channels.  Response channel types depend on
	// the request type, so we have to use interface{}, but every value in this
	// map will be a channel of some type.
	responseChannels map[int]interface{}
}

// The global (and single) GopherJS bridge instance.  This will be wrapped into
// a JavaScript object called _GIBBridge which host environments can use to
// register their handlers
var bridge *Bridge = nil

// Bridge method for JavaScript to send control messages.  The incoming message
// should be a base64-encoded set of bytes representing a UTF-8 string.
func (b *Bridge) SendControlMessage(messageBase64 string) {
	// Send the message asychronously so JavaSciprt doesn't block
	// TODO: This could conceivably result in messages being delivered out of
	// order...
	go func() {
		b.controlChannel <- b.base64DecodeString(messageBase64)
	}()
}

// Bridge methods for JavaScript to register request handlers

func (b *Bridge) SetConnectHandler(handler func(int, string)) {
	b.connectHandler = handler
}

func (b *Bridge) SetConnectionReadHandler(handler func(int, int, int)) {
	b.connectionReadHandler = handler
}

func (b *Bridge) SetConnectionWriteHandler(handler func(int, int, string)) {
	b.connectionWriteHandler = handler
}

func (b *Bridge) SetConnectionCloseHandler(handler func(int, int)) {
	b.connectionCloseHandler = handler
}

func (b *Bridge) SetListenHandler(handler func(int, string)) {
	b.listenHandler = handler
}

func (b *Bridge) SetListenerAcceptHandler(handler func(int, int)) {
	b.listenerAcceptHandler = handler
}

func (b *Bridge) SetListenerCloseHandler(handler func(int, int)) {
	b.listenerCloseHandler = handler
}

// Utility methods for request/respond methods to generate and access response
// channels
func (b *Bridge) pushResponseChannel(channel interface{}) int {
	// Grab the sequence lock
	b.sequenceLock.Lock()
	defer b.sequenceLock.Unlock()

	// Compute the sequence
	sequence := b.nextSequence
    if _, ok := b.responseChannels[sequence]; ok {
    	panic("sequence overlap")
    }
    b.nextSequence++

    // Store the response channel
    b.responseChannels[sequence] = channel
    
    // All done
    return sequence
}

func (b *Bridge) popResponseChannel(sequence int) interface{} {
	// Grab the sequence lock
	b.sequenceLock.Lock()
	defer b.sequenceLock.Unlock()

	// Grab the channel
	channel, ok := b.responseChannels[sequence]
	if !ok {
		panic("invalid sequence identifier")
	}

	// Remove the channel from the map
	delete(b.responseChannels, sequence)

	// All done
	return channel
}

// Bridge methods for GopherJS IPC Bridge to request operations

type connectResponse struct {
    connectionId int
    err error
}

func (b *Bridge) connect(path string) (int, error) {
	// Verify the host handler for this operation
	if b.connectHandler == nil {
		return 0, errors.New("connect operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan connectResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Convert the path to base64 encoding
	pathBase64 := b.base64EncodeString(path)

	// Dispatch the request to the host
	b.connectHandler(sequence, pathBase64)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.connectionId, response.err
}

func (b *Bridge) RespondConnect(sequence, connectionId int, errBase64 string) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan connectResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := connectResponse{connectionId: connectionId}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type connectionReadResponse struct {
    buffer []byte
    err error
}

func (b *Bridge) connectionRead(connectionId, length int) ([]byte, error) {
	// Verify the host handler for this operation
	if b.connectionReadHandler == nil {
		return make([]byte, 0),
			   errors.New("connection read operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan connectionReadResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Dispatch the request to the host
	b.connectionReadHandler(sequence, connectionId, length)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.buffer, response.err
}

func (b *Bridge) RespondConnectionRead(
	sequence int,
	bufferBase64,
	errBase64 string,
) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan connectionReadResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Decode the buffer
	// TODO: Think about how we might be able to decode directly into the read
	// buffer.  It would be difficult, particularly if we wanted to support
	// generic base64 decoders.  It would also require us to associate the
	// original buffer with the request somehow.
	buffer := b.base64DecodeBytes(bufferBase64)

	// Create the response
	response := connectionReadResponse{buffer: buffer}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type connectionWriteResponse struct {
    count int
    err error
}

func (b *Bridge) connectionWrite(connectionId int, buffer []byte) (int, error) {
	// Verify the host handler for this operation
	if b.connectionWriteHandler == nil {
		return 0, errors.New("connection write operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan connectionWriteResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Convert the buffer to base64 encoding
	bufferBase64 := b.base64EncodeBytes(buffer)

	// Dispatch the request to the host
	b.connectionWriteHandler(sequence, connectionId, bufferBase64)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.count, response.err
}

func (b *Bridge) RespondConnectionWrite(sequence, count int, errBase64 string) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan connectionWriteResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := connectionWriteResponse{count: count}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type connectionCloseResponse struct {
    err error
}

func (b *Bridge) connectionClose(connectionId int) error {
	// Verify the host handler for this operation
	if b.connectionCloseHandler == nil {
		return errors.New("connection close operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan connectionCloseResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Dispatch the request to the host
	b.connectionCloseHandler(sequence, connectionId)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.err
}

func (b *Bridge) RespondConnectionClose(sequence int, errBase64 string) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan connectionCloseResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := connectionCloseResponse{}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type listenResponse struct {
    listenerId int
    err error
}

func (b *Bridge) listen(path string) (int, error) {
	// Verify the host handler for this operation
	if b.listenHandler == nil {
		return 0, errors.New("listen operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan listenResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Convert the path to base64 encoding
	pathBase64 := b.base64EncodeString(path)

	// Dispatch the request to the host
	b.listenHandler(sequence, pathBase64)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.listenerId, response.err
}

func (b *Bridge) RespondListen(sequence, listenerId int, errBase64 string) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan listenResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := listenResponse{listenerId: listenerId}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type listenerAcceptResponse struct {
    connectionId int
    err error
}

func (b *Bridge) listenerAccept(listenerId int) (int, error) {
	// Verify the host handler for this operation
	if b.listenerAcceptHandler == nil {
		return 0, errors.New("listener accept operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan listenerAcceptResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Dispatch the request to the host
	b.listenerAcceptHandler(sequence, listenerId)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.connectionId, response.err
}

func (b *Bridge) RespondListenerAccept(
	sequence,
	connectionId int,
	errBase64 string,
) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan listenerAcceptResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := listenerAcceptResponse{connectionId: connectionId}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

type listenerCloseResponse struct {
    err error
}

func (b *Bridge) listenerClose(listenerId int) error {
	// Verify the host handler for this operation
	if b.listenerCloseHandler == nil {
		return errors.New("listener close operation not supported by host")
	}

	// Create a response channel (buffer it so JavaScript can write to it
	// without blocking)
	responseChannel := make(chan listenerCloseResponse, 1)

	// Register it and get a sequence
	sequence := b.pushResponseChannel(responseChannel)

	// Dispatch the request to the host
	b.listenerCloseHandler(sequence, listenerId)

	// Wait on the response
	response := <- responseChannel

	// All done
	return response.err
}

func (b *Bridge) RespondListenerClose(sequence int, errBase64 string) {
	// Get the generic response chanel
	genericResponseChannel := b.popResponseChannel(sequence)

	// Convert it to a more specific response channel
	responseChannel, ok := genericResponseChannel.(chan listenerCloseResponse)
	if !ok {
		panic("invalid response channel type")
	}

	// Create the response
	response := listenerCloseResponse{}

	// Set the error if necessary
	if errBase64 != "" {
		response.err = errors.New(b.base64DecodeString(errBase64))
	}

	// Send the response (channel is buffered, so this won't block)
	responseChannel <- response
}

// Default methods for base64 encoding/decoding

func defaultBase64EncodeBytes(b []byte) string {
	return base64.StdEncoding.EncodeToString(b)
}

func defaultBase64DecodeBytes(s string) []byte {
	// Decode and watch for errors (we panic in the case of errors since they
	// are somewhat non-recoverable (the host is sending gibberish))
	buffer, err := base64.StdEncoding.DecodeString(s)
	if err != nil {
		panic(err.Error())
	}

	// All done
	return buffer
}

func defaultBase64EncodeString(s string) string {
	return defaultBase64EncodeBytes([]byte(s))
}

func defaultBase64DecodeString(s string) string {
	return string(defaultBase64DecodeBytes(s))
}

// Entry point for initialization
func Initialize() (chan string, error) {
	// Check if the bridge has already been initialized
	if bridge != nil {
		return nil, errors.New("bridge already initialized")
	}

	// Create the control channel
	controlChannel := make(chan string)

	// Create the response channel map
	responseChannels := make(map[int]interface{})

	// TODO: Investigate using JavaScript-accelerated base64 encoding/decoding
	// to replace default methods

	// Create the bridge
	bridge = &Bridge{
		controlChannel: controlChannel,
		base64EncodeBytes: defaultBase64EncodeBytes,
		base64DecodeBytes: defaultBase64DecodeBytes,
		base64EncodeString: defaultBase64EncodeString,
		base64DecodeString: defaultBase64DecodeString,
		responseChannels: responseChannels,
	}

	// Create the bridge wrapper that JavaScript can access
	js.Global.Set("_GIBBridge", js.MakeWrapper(bridge))

    // Return the control channel for the caller to monitor
    return controlChannel, nil
}
