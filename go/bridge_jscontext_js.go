// +build js

package ipc

// System imports
import (
	"encoding/base64"
)

// GopherJS imports
import "github.com/gopherjs/gopherjs/js"

// JSContextBridge implements the Bridge interface for Cocoa JSContext
// instances, e.g. raw JSContexts or those found in Cocoa WebViews.
type JSContextBridge struct {
	// The host object provided via the JSExport protocol
	hostObject *js.Object
}

func init() {
	// Create a JavaScript wrapper function that the host can use to invoke the
	// HostInitialize function with a JSContextBridge
	js.Global.Set(
		"_GIBJSContextBridgeInitialize",
		func(hostObject *js.Object, message *js.Object) {
			// Create a new JSContextBridge
			bridge := &JSContextBridge{hostObject: hostObject}

			// Call HostInitialize
			HostInitialize(bridge, message.String())
		},
	)
}

func (b *JSContextBridge) Connect(endpoint string) chan ConnectResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"connectWithCallback",
		endpoint,
		func (connectionId int, errorMessage string) {
			resultChannel <- ConnectResult{
				connectionId: connectionId,
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) ConnectionRead(
	connectionId,
	length int,
) chan ConnectionReadResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionReadResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"connectionReadWithLengthWithCallback",
		connectionId,
		length,
		func (data64, errorMessage string) {
			// Decode the data
			data, err := base64.StdEncoding.DecodeString(data64)
			if err != nil {
				panic("host sent gibberish data")
			}

			// Create and send the result
			resultChannel <- ConnectionReadResult{
				data: data,
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) ConnectionWrite(
	connectionId int,
	data []byte,
) chan ConnectionWriteResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionWriteResult, 1)

	// Encode the data
	data64 := base64.StdEncoding.EncodeToString(data)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"connectionWriteWithDataWithCallback",
		connectionId,
		data64,
		func (count int, errorMessage string) {
			resultChannel <- ConnectionWriteResult{
				count: count,
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) ConnectionClose(
	connectionId int,
) chan ConnectionCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionCloseResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"connectionCloseWithCallback",
		connectionId,
		func (errorMessage string) {
			resultChannel <- ConnectionCloseResult{
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) Listen(endpoint string) chan ListenResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"listenWithCallback",
		endpoint,
		func (listenerId int, errorMessage string) {
			resultChannel <- ListenResult{
				listenerId: listenerId,
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) ListenerAccept(
	listenerId int,
) chan ListenerAcceptResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerAcceptResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"listenerAcceptWithCallback",
		listenerId,
		func (connectionId int, errorMessage string) {
			resultChannel <- ListenerAcceptResult{
				connectionId: connectionId,
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *JSContextBridge) ListenerClose(
	listenerId int,
) chan ListenerCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerCloseResult, 1)

	// Forward the request to the host with a callback it can use to write to
	// the result channel
	b.hostObject.Call(
		"listenerCloseWithCallback",
		listenerId,
		func (errorMessage string) {
			resultChannel <- ListenerCloseResult{
				err: ErrorFromErrorMessage(errorMessage),
			}
		},
	)

	// Return the result channel for the caller to wait on
	return resultChannel
}
