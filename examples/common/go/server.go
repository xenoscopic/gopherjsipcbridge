// +build !js

package main

// System imports
import (
	"os"
	"fmt"
)

// GopherJSIPCBridge imports
import ipc "github.com/havoc-io/gopherjsipcbridge/go"


func main() {
	// Parse command line arguments - there should be only one (aside from the
	// process image name): the name of the socket on which to bind
	if len(os.Args) != 2 {
		fmt.Println("invalid arguments")
		return
	}

	// Create a listener
	fmt.Println("Listening on IPC path:", os.Args[1])
	listener, err := ipc.ListenIPC(os.Args[1])
	if err != nil {
		fmt.Println("error: IPC listening failed:", err)
		return
	}

	// Accept the first connection
	fmt.Println("Accepting IPC connection...")
	connection, err := listener.Accept()
	if err != nil {
		fmt.Println("error: IPC connection accept failed:", err)
		return
	}

	// Run the benchmark server routine
	benchmarkServer(connection)

	// Clean up
	fmt.Println("Cleaning up...")
	connection.Close()
	listener.Close()
}
