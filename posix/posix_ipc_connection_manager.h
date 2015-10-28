#ifndef POSIX_IPC_CONNECTION_MANAGER_H
#define POSIX_IPC_CONNECTION_MANAGER_H


// C standard includes
#include <cstdlib>
#include <cstdint>

// Standard includes
#include <string>
#include <functional>
#include <thread>
#include <mutex>
#include <map>

// asio includes
#define ASIO_STANDALONE
#include <asio.hpp>


namespace gib {


// POSIXIPCConnectionManager implements IPC connection facilities on POSIX
// platforms using UNIX domain sockets.  It is completely thread-safe.  Handlers
// passed to the connection manager will be invoked *during* the call that
// passed the handler (if there is an error starting the asynchronous operation
// or the operation can be completed synchronously without blocking) or will be
// invoked from the POSIXIPCConnectionManager's I/O pumping thread.  Callers and
// handlers must be prepared for either eventuality.  All open connections will
// automatically be closed upon destruction.
class POSIXIPCConnectionManager final {

public:

    // Constructor
    POSIXIPCConnectionManager();

    // Disable copying
    POSIXIPCConnectionManager(const POSIXIPCConnectionManager &) = delete;
    POSIXIPCConnectionManager& operator=(
        const POSIXIPCConnectionManager &
    ) = delete;

    // Destructor
    ~POSIXIPCConnectionManager();

    // Asynchronously create a new connection
    void connect_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously read from a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // read.
    void connection_read_async(
        std::int32_t connection_id,
        void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    );

    // Asynchronously write to a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // write.
    void connection_write_async(
        std::int32_t connection_id,
        const void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    );

    // Asynchronously close a connection
    void connection_close_async(
        std::int32_t connection_id,
        std::function<void(const std::string &)> handler
    );

    // Asynchronously begin listening
    void listen_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously accept a connection
    void listener_accept_async(
        std::int32_t listener_id,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously close a listener
    void listener_close_async(
        std::int32_t listener_id,
        std::function<void(const std::string &)> handler
    );

private:

    // The underlying I/O service
    asio::io_service _io_service;

    // The thread which pumps the underlying I/O service
    std::thread _io_service_pump;

    // Lock for connection/listener ids/maps
    std::mutex _lock;

    // The next connection id
    std::int32_t _next_connection_id;

    // Map from connection id to connection socket
    std::map<std::int32_t, asio::local::stream_protocol::socket> _connections;

    // The next listener id
    std::int32_t _next_listener_id;

    // Map from listener id to acceptor
    std::map<std::int32_t, asio::local::stream_protocol::acceptor> _listeners;

    // Map from listener id to endpoint (socket filesystem path)
    // NOTE: We have to manually track this so that we can clean up socket paths
    // from disk.  Asio doesn't do this by default, but Go does, so to keep
    // consistency we perform this removal on listener creation failure,
    // listener close, and in the destructor.  Also, oddly, there doesn't seem
    // to be a way to access an acceptor's endpoint's path - it throws when you
    // try to access it.
    std::map<std::int32_t, std::string> _listener_endpoints;

};


} // namespace gib


#endif // POSIX_IPC_CONNECTION_MANAGER_H
