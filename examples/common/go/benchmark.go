package main

// System imports
import (
	"net"
	"fmt"
	"net/rpc"
	"time"
)

// RPCActions represents a simple RPC interface
type RPCActions struct{}

type AddArgs struct {
	A, B int
}

// Add computes the sum of two numbers
func (*RPCActions) Add(args *AddArgs, result *int) (error) {
	*result = args.A + args.B
	return nil
}

// SayHello prints a friendly message
func (*RPCActions) SayHello(name, result *string) (error) {
	*result = fmt.Sprintf("Well hello there %s!", name)
	return nil
}

func benchmarkServer(c net.Conn) {
	// Print information
	fmt.Println("Running benchmark server...")

	// TODO: Implement bandwidth test

	// Create an RPC server
	fmt.Println("Creating RPC server...")
	server := rpc.NewServer()

	// Register RPC interface
	fmt.Println("Registering RPC interface...")
	err := server.Register(new(RPCActions))
	if err != nil {
		fmt.Println("error: unable to Register RPC interface")
		return
	}

	// Serve the connection until the client hangs up
	fmt.Println("Serving RPC interface to client...")
	server.ServeConn(c)

	// All done
	fmt.Println("Benchmarking server complete.")
}

func benchmarkClient(c net.Conn) {
	// Print information
	fmt.Println("Benchmarking connection...")

	// TODO: Implement bandwidth test

	// Create an RPC client
	fmt.Println("Creating RPC client...")
	client := rpc.NewClient(c)

	// Invoke Add over many times and test the average response time
	n := 1000
	fmt.Println("Invoking Add over RPC", n, "times...")
	start := time.Now()
	for i := 0; i < n; i++ {
		args := &AddArgs{i, i + 1}
		var result int
		err := client.Call("RPCActions.Add", args, &result)
		if err != nil {
			fmt.Println("error: RPC invocation failed:", err)
			return
		}
		if result != ((2 * i) + 1) {
			fmt.Println("error: RPC invocation returned wrong result")
			return
		}
	}
	elapsed := time.Since(start)
	fmt.Printf(
		"%d invocations took %fs (%fs per call)\n",
		n,
		elapsed.Seconds(),
		elapsed.Seconds() / float64(n),
	)

	// TODO: Add test of SayHello invocation

	// All done
	fmt.Println("Benchmarking client complete.")
}
