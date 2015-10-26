package main

// System imports
import (
	"os"
	"fmt"
)

// GopherJSIPCBridge imports
import gib "github.com/havoc-io/gopherjsipcbridge/go"

func main() {
	// Print some information
	fmt.Println("GopherJS IPC Bridge Demo")

	// Parse command line arguments - there should be only one (aside from the
	// process image name): the name of the socket on which to connect
	if len(os.Args) != 2 {
		fmt.Println("invalid arguments")
		return
	}
	
	// Request that a connection be create
	fmt.Println("Connecting to IPC path:", os.Args[1])
	connection, err := gib.DialIPC(os.Args[1])
	if err != nil {
		fmt.Println("error: IPC connection failed:", err)
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
