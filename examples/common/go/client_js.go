package main

// System imports
import (
	"fmt"
)

// GopherJSIPCBridge imports
import ipc "github.com/havoc-io/gopherjsipcbridge/go"

func main() {
	// Print some information
	fmt.Println("Initializing GopherJS side of bridge...")

	// Start the initialization sequence
	controlChannel := ipc.ClientInitialize()

	// Wait for the initialization message to come from the control channel.
	// This should indicate that the server is up and running.
	fmt.Println("Waiting for IPC path...")
	ipcPath := <-controlChannel
	
	// Request that a connection be create
	fmt.Println("Connecting to IPC path:", ipcPath)
	connection, err := ipc.DialIPC(ipcPath)
	if err != nil {
		fmt.Println("error: IPC connection failed:", err)
		return
	}

	// Pass the connection to the benchmark
	benchmarkClient(connection)

	// Close the connection
	fmt.Println("Closing IPC connection...")
	err = connection.Close()
	if err != nil {
		fmt.Println("error: IPC connection shutdown failed:", err)
	}
}
