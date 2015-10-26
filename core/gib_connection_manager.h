#ifndef GIB_CONNECTION_MANAGER_H
#define GIB_CONNECTION_MANAGER_H


// C standard includes
#include <cstdlib>
#include <cstdint>

// Standard includes
#include <string>
#include <functional>
#include <thread>

// asio includes
#define ASIO_STANDALONE
#include <asio.hpp>


namespace gib {


// Abstract base class for connection management.  All implementations of
// ConnectionManager are implicitly non-copyable.  All implementations must also
// be thread-safe.  Handlers passed to the connection manager will be invoked
// *during* the call that passed the handler (if there is an error starting the
// asynchronous operation or the operation can be completed synchronously
// without blocking) or will be invoked from the ConnectionManager's I/O pumping
// thread.  Callers/handlers must be prepared for either eventuality.  All
// implementations must close any managed connections automatically upon
// destruction.
class ConnectionManager {

public:

    // Constructor
    ConnectionManager();

    // Disable copying
    ConnectionManager(const ConnectionManager &) = delete;
    ConnectionManager& operator=(const ConnectionManager &) = delete;

    // Destructor
    virtual ~ConnectionManager();

    // Asynchronously create a new connection
    virtual void connect_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    ) = 0;

    // Asynchronously read from a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // read.
    virtual void connection_read_async(
        std::int32_t connection_id,
        void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    ) = 0;

    // Asynchronously write to a connection.  The client is responsible for
    // ensuring that the underlying buffer persists for the duration of the
    // write.
    virtual void connection_write_async(
        std::int32_t connection_id,
        const void * buffer,
        std::size_t length,
        std::function<void(std::size_t, const std::string &)> handler
    ) = 0;

    // Asynchronously close a connection
    virtual void connection_close_async(
        std::int32_t connection_id,
        std::function<void(const std::string &)> handler
    ) = 0;

    // Asynchronously begin listening
    virtual void listen_async(
        const std::string & path,
        std::function<void(std::int32_t, const std::string &)> handler
    ) = 0;

    // Asynchronously accept a connection
    virtual void listener_accept_async(
        std::int32_t listener_id,
        std::function<void(std::int32_t, const std::string &)> handler
    ) = 0;

    // Asynchronously close a listener
    virtual void listener_close_async(
        std::int32_t listener_id,
        std::function<void(const std::string &)> handler
    ) = 0;

protected:

    // The underlying I/O service
    asio::io_service _io_service;

private:

    // The thread which pumps the underlying I/O service
    std::thread _io_service_pump;

};


} // namespace gib


#endif // GIB_CONNECTION_MANAGER_H
