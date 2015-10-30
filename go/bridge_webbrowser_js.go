// +build js

package ipc

// System imports
import "encoding/base64"

// GopherJS imports
import "github.com/gopherjs/gopherjs/js"

// WebBrowserBridge implements the Bridge interface for
// System.Windows.Forms.WebBrowser instances.
type WebBrowserBridge struct {
	// The object provided via the WebBrowser's ObjectForScripting property
	// TODO: Benchmark performance without caching this
	hostProxy *js.Object

	// Request/response sequencer for managing responses
	sequences *sequencer
}

func init() {
	// Create a JavaScript wrapper function that the host can use to invoke the
	// HostInitialize function with a WebBrowserBridge
	js.Global.Set(
		"_GIBWebBrowserBridgeInitialize",
		func(message *js.Object) {
			// Create a new WebBrowserBridge
			bridge := &WebBrowserBridge{
				hostProxy: js.Global.Get("external"),
				sequences: newSequencer(),
			}

			// Create functions that the bridge can use to call in and respond
			// to queries
			// NOTE: For the WKWebView bridge, we were able to just create a
			// wrapper object around the bridge and could call that by
			// evaluating JavaScript.  I had hoped a similar approach would work
			// here, but it seems that the HtmlDocument.InvokeScript method
			// can't invoke methods of the wrapper object, only global
			// functions.
			// TODO: I suppose we could make these methods private now that we
			// don't need to export them for direct wrapping
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondConnect",
				func(sequence, connectionId int, errorMessage string) {
					bridge.RespondConnect(sequence, connectionId, errorMessage)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondConnectionRead",
				func(sequence int, data64, errorMessage string) {
					bridge.RespondConnectionRead(sequence, data64, errorMessage)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondConnectionWrite",
				func(sequence, count int, errorMessage string) {
					bridge.RespondConnectionWrite(sequence, count, errorMessage)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondConnectionClose",
				func(sequence int, errorMessage string) {
					bridge.RespondConnectionClose(sequence, errorMessage)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondListen",
				func(sequence, listenerId int, errorMessage string) {
					bridge.RespondListen(sequence, listenerId, errorMessage)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondListenerAccept",
				func(sequence, connectionId int, errorMessage string) {
					bridge.RespondListenerAccept(
						sequence,
						connectionId,
						errorMessage,
					)
				},
			)
			js.Global.Set(
				"_GIBWebBrowserBridgeRespondListenerClose",
				func(sequence int, errorMessage string) {
					bridge.RespondListenerClose(sequence, errorMessage)
				},
			)

			// Call HostInitialize
			HostInitialize(bridge, message.String())
		},
	)
}

func (b *WebBrowserBridge) Connect(endpoint string) chan ConnectResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("Connect", endpoint, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondConnect(
	sequence,
	connectionId int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectResult{
		connectionId: connectionId,
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) ConnectionRead(
	connectionId,
	length int,
) chan ConnectionReadResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionReadResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("ConnectionRead", connectionId, length, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondConnectionRead(
	sequence int,
	data64 string,
	errorMessage string,
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
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) ConnectionWrite(
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
	b.hostProxy.Call("ConnectionWrite", connectionId, data64, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondConnectionWrite(
	sequence,
	count int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectionWriteResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectionWriteResult{
		count: count,
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) ConnectionClose(
	connectionId int,
) chan ConnectionCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ConnectionCloseResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("ConnectionClose", connectionId, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondConnectionClose(
	sequence int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ConnectionCloseResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ConnectionCloseResult{
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) Listen(endpoint string) chan ListenResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("Listen", endpoint, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondListen(
	sequence,
	listenerId int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenResult{
		listenerId: listenerId,
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) ListenerAccept(
	listenerId int,
) chan ListenerAcceptResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerAcceptResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("ListenerAccept", listenerId, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondListenerAccept(
	sequence,
	connectionId int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenerAcceptResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenerAcceptResult{
		connectionId: connectionId,
		err: ErrorFromErrorMessage(errorMessage),
	}
}

func (b *WebBrowserBridge) ListenerClose(
	listenerId int,
) chan ListenerCloseResult {
	// Create a buffered (non-blocking) result channel
	resultChannel := make(chan ListenerCloseResult, 1)

	// Record the result channel and generate a sequence
	sequence := b.sequences.push(resultChannel)

	// Forward the request to the host with a sequence it can use to respond
	b.hostProxy.Call("ListenerClose", listenerId, sequence)

	// Return the result channel for the caller to wait on
	return resultChannel
}

func (b *WebBrowserBridge) RespondListenerClose(
	sequence int,
	errorMessage string,
) {
	// Get the response channel
	resultChannel, ok := b.sequences.pop(sequence).(chan ListenerCloseResult)
	if !ok {
		panic("invalid response channel type")
	}

	// Respond
	resultChannel <- ListenerCloseResult{
		err: ErrorFromErrorMessage(errorMessage),
	}
}
