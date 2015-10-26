#ifndef GIB_CONNECTION_MANAGER_POSIX_H
#define GIB_CONNECTION_MANAGER_POSIX_H


// Standard includes
#include <map>
#include <mutex>

// GopherJSIPCBridge includes
#include "gib_connection_manager.h"


namespace gib {


// ConnectionManager implementation for POSIX systems.  All implementations of
// ConnectionManager are implicitly non-copyable.  All implementations must also
// be thread-safe.  Handlers passed to the connection manager will be invoked
// *during* the call that passed the handler (if there is an error starting the
// asynchronous operation or the operation can be completed synchronously
// without blocking) or will be invoked from the ConnectionManager's I/O pumping
// thread.  Callers/handlers must be prepared for either eventuality.  All
// implementations must close any managed connections automatically upon
// destruction.
class ConnectionManagerPosix : public ConnectionManager {

public:

    // Constructor
    ConnectionManagerPosix();

    // Destructor
    virtual ~ConnectionManagerPosix();

    // Asynchronously create a new connection
    virtual void connect_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously read from a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // read.
    virtual void connection_read_async(
        std::int32_t connection_id,
        void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    );

    // Asynchronously write to a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // write.
    virtual void connection_write_async(
        std::int32_t connection_id,
        const void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    );

    // Asynchronously close a connection
    virtual void connection_close_async(
        std::int32_t connection_id,
        std::function<void(const std::string &)> handler
    );

    // Asynchronously begin listening
    virtual void listen_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously accept a connection
    virtual void listener_accept_async(
        std::int32_t listener_id,
        std::function<void(std::int32_t, const std::string &)> handler
    );

    // Asynchronously close a listener
    virtual void listener_close_async(
        std::int32_t listener_id,
        std::function<void(const std::string &)> handler
    );

private:

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


#endif // GIB_CONNECTION_MANAGER_POSIX_H
