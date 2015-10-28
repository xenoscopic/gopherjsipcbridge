// +build js

package ipc

// System imports
import (
	"encoding/base64"
)

// GopherJS imports
import (
	"github.com/gopherjs/gopherjs/js"
	sync "github.com/gopherjs/gopherjs/nosync"
)

const (
	WKWebViewBridgeActionConnect = iota
	WKWebViewBridgeActionConnectionRead
	WKWebViewBridgeActionConnectionWrite
	WKWebViewBridgeActionConnectionClose
	WKWebViewBridgeActionListen
	WKWebViewBridgeActionListenerAccept
	WKWebViewBridgeActionListenerClose
)

// WKWebViewBridge implements the Bridge interface for Cocoa WKWebView
// instances.
type WKWebViewBridge struct {
	// Faux lock, mostly for future-proof code
	sync.Mutex

	// The message posting function provided via WKWebView's message handling
	// infrastructure
	hostMessenger *js.Object

	// Request/response sequencer for managing responses
	sequences *sequencer
}

func init() {
	// Create a JavaScript wrapper function that the host can use to invoke the
	// HostInitialize function with a WKWebViewBridge
	js.Global.Set(
		"_GIBWKWebViewBridgeInitialize",
		func(message64 *js.Object) {
			// Get the messenger object
			// NOTE: For some reason, we can't get the postMessage method on
			// this object and use Invoke(...) on it directly, it just doesn't
			// work.  I don't know why, but for some reason doing
			// Call("postMessage", ...) does work.
			hostMessenger := js.Global.Get(
				"webkit",
			).Get(
				"messageHandlers",
			).Get(
				"_GIBWKWebViewBridgeMessageHandler",
			)

			// Create a new WKWebViewBridge
			bridge := &WKWebViewBridge{
				hostMessenger: hostMessenger,
				sequences: newSequencer(),
			}

			// Create a wrapper for the host to interface with
			js.Global.Set("_GIBWKWebViewBridge", js.MakeWrapper(bridge))

			// Decode the initialization message
			messageBytes, err := base64.StdEncoding.DecodeString(
				message64.String(),
			)
			if err != nil {
				panic("unable to decode initialization message")
			}

			// Call HostInitialize
			HostInitialize(bridge, string(messageBytes))
		},
	)
}

func (b *WKWebViewBridge) Connect(endpoint string) chan ConnectResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionConnect,
		"endpoint": endpoint,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondConnect(
	sequence,
	connectionId int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectResult{
		connectionId: connectionId,
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) ConnectionRead(
	connectionId,
	length int,
) chan ConnectionReadResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionReadResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionConnectionRead,
		"connectionId": connectionId,
		"length": length,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondConnectionRead(
	sequence int,
	data64 string,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectionReadResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Decode the data
	data, err := base64.StdEncoding.DecodeString(data64)
	if err != nil {
		panic("host sent gibberish data")
	}

	// Respond
	resultChannel <- ConnectionReadResult{
		data: data,
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) ConnectionWrite(
	connectionId int,
	data []byte,
) chan ConnectionWriteResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionWriteResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Encode the data
	data64 := base64.StdEncoding.EncodeToString(data)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionConnectionWrite,
		"connectionId": connectionId,
		"data64": data64,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondConnectionWrite(
	sequence,
	count int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectionWriteResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectionWriteResult{
		count: count,
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) ConnectionClose(
	connectionId int,
) chan ConnectionCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionCloseResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionConnectionClose,
		"connectionId": connectionId,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondConnectionClose(
	sequence int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectionCloseResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectionCloseResult{
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) Listen(endpoint string) chan ListenResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionListen,
		"endpoint": endpoint,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondListen(
	sequence,
	listenerId int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenResult{
		listenerId: listenerId,
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) ListenerAccept(
	listenerId int,
) chan ListenerAcceptResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerAcceptResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionListenerAccept,
		"listenerId": listenerId,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondListenerAccept(
	sequence,
	connectionId int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenerAcceptResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenerAcceptResult{
		connectionId: connectionId,
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}

func (b *WKWebViewBridge) ListenerClose(
	listenerId int,
) chan ListenerCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerCloseResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostMessenger.Call("postMessage", map[string]interface{}{
		"sequence": sequence,
		"action": WKWebViewBridgeActionListenerClose,
		"listenerId": listenerId,
	})

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WKWebViewBridge) RespondListenerClose(
	sequence int,
	errorMessage64 string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenerCloseResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenerCloseResult{
		err: ErrorFromBase64EncodedErrorMessage(errorMessage64),
	}
}
