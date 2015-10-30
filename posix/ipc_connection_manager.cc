#include "ipc_connection_manager.h"

// Standard includes
#include <stdexcept>

// POSIX includes
#include <unistd.h>


gib::IPCConnectionManager::IPCConnectionManager() :
_io_service(),
_io_service_pump([this]() {
    // Create a work object to keep the I/O service loop from exiting when there
    // are no pending requests
    asio::io_service::work idle(_io_service);

    // Process I/O requests
    _io_service.run();
}),
_next_connection_id(0),
_next_listener_id(0) {

}


gib::IPCConnectionManager::~IPCConnectionManager() {
    // Cancel the run loop being executed in the pump thread (this cancels the
    // work object, allowing the run() call to return)
    _io_service.stop();

    // Wait for the pump thread to die.  After this, no more handlers will be
    // invoked.
    _io_service_pump.join();

    // Upon destruction, listeners will automatically be closed, but their
    // filesystem endpoints won't automatically be removed by Asio.  We remove
    // these in listener_close_async, but we also want to accomodate users that
    // rely on RAII to clean up these paths.

    // Close all listeners automatically by destructing them (we do this
    // manually only so we can remove their endpoints - we let connections be
    // closed when their map destructs)
    _listeners.clear();

    // Iterate over endpoint paths and remove them from disk and the map
    for (auto&& endpoint : _listener_endpoints) {
        unlink(endpoint.second.c_str());
    }
}


void gib::IPCConnectionManager::connect_async(
    const std::string & path,
    std::function<void(std::int32_t, const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Compute the next connection id.  Watch for overflow, because we use -1 as
    // the invalid identifier.
    if (_next_connection_id < 0) {
        handler(-1, "connection ids exhausted");
        return;
    }
    std::int32_t connection_id = _next_connection_id++;

    // Create the socket
    // TODO: If we move to C++14 (and get generalized lambda captures), it'd be
    // nice to create the connection and then add it to the connection map after
    // connection has succeeded (that way we don't have to do an add/remove and
    // burn a connection id for failed connections).  But sockets are
    // non-copyable, and we don't have a way to std::move them into the handler
    // lambda, so for now we have to create them in-place to support
    // asynchronous operations.
    _connections.emplace(
        std::piecewise_construct,
        std::forward_as_tuple(connection_id),
        std::forward_as_tuple(_io_service)
    );

    // Connect asynchronously
    _connections.find(connection_id)->second.async_connect(
        asio::local::stream_protocol::endpoint(path),
        [this, connection_id, handler](const asio::error_code & error) {
            // Check for an error
            if (error) {
                // Lock the maps
                // NOTE: This is safe to do in our handler because asio
                // guarantees it never calls handlers from inside the caller
                // (which in our case already holds the lock and would deadlock
                // if we tried to lock again).  We could switch to a recursive
                // mutex, but it's not worth the performance drop.
                std::lock_guard<std::mutex> lock(_lock);

                // Erase the entry
                // NOTE: Don't do this with a captured iterator because it could
                // become invalidated before this handler is invoked
                _connections.erase(connection_id);

                // Notify the handler of the error
                handler(-1, error.message());
            } else {
                // Notify the handler of success
                handler(connection_id, "");
            }
        }
    );
}


void gib::IPCConnectionManager::connection_read_async(
    std::int32_t connection_id,
    void * buffer,
    std::size_t length,
    std::function<void(std::size_t, const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Verify that the connection exists
    auto connection_entry = _connections.find(connection_id);
    if (connection_entry == _connections.end()) {
        // Call the handler with the error
        handler(0, "invalid connection id");

        // Bail
        return;
    }

    // Handle the case of 0 read length.  It's technically not an error, but
    // there is no need to do it asynchronously.
    if (length == 0) {
        handler(0, "");
        return;
    }

    // Read asynchronously
    // NOTE: We use the socket's async_read_some method instead of the
    // asio::async_read method because this better matches the behavior of the
    // Read method in Go io.Reader interface.  Specifically, the async_read
    // method waits until ALL data requested is available or an error before
    // returning, whereas the async_read_some method won't necessarily wait
    // until all bytes are available before returning (which is what an
    // io.Reader should do).  There is one small caveat to this, see the HACK
    // below.
    connection_entry->second.async_read_some(
        asio::buffer(buffer, length),
        [this, connection_id, buffer, length, handler](
            const asio::error_code & error,
            std::size_t bytes_transfered
        ) {
            // HACK: The async_read_some method technically doesn't say that it
            // will return a non-empty buffer if there is no error, so it could
            // conceivably return an empty buffer without an error.  This is
            // discouraged in Go's io.Reader interface, so if we encounter this
            // situation, just re-queue the read.
            if (!error && bytes_transfered == 0) {
                connection_read_async(connection_id, buffer, length, handler);
                return;
            }

            // Check for an error
            std::string error_message = "";
            if (error) {
                error_message = error.message();
            }

            // Notify the handler
            handler(bytes_transfered, error_message);
        }
    );
}


void gib::IPCConnectionManager::connection_write_async(
    std::int32_t connection_id,
    const void * buffer,
    std::size_t length,
    std::function<void(std::size_t, const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Verify that the connection exists
    auto connection_entry = _connections.find(connection_id);
    if (connection_entry == _connections.end()) {
        handler(0, "invalid connection id");
    }

    // Handle the case of 0 write length.  It's technically not an error, but
    // there is no need to do it asynchronously.
    if (length == 0) {
        handler(0, "");
        return;
    }

    // Write asynchronously
    // NOTE: We use the asio::async_write method instead of the socket's
    // async_write_some method because this better matches the behavior of the
    // Write method in Go io.Writer interface.  Specifically, the
    // async_write_some method may return before all data has been written
    // without an error, whereas the async_write will wait until either all data
    // has been sent or an error has occurred before returning (which is what an
    // io.Writer should do).
    asio::async_write(
        connection_entry->second,
        asio::buffer(buffer, length),
        [handler](
            const asio::error_code& error,
            std::size_t bytes_transferred
        ) {
            // Check for an error
            std::string error_message = "";
            if (error) {
                error_message = error.message();
            }

            // Notify the handler
            handler(bytes_transferred, error_message);
        }
    );
}


void gib::IPCConnectionManager::connection_close_async(
    std::int32_t connection_id,
    std::function<void(const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Verify that the connection exists
    auto connection_entry = _connections.find(connection_id);
    if (connection_entry == _connections.end()) {
        handler("invalid connection id");
    }

    // There is no asynchronous close method for sockets, so just close it
    connection_entry->second.close();

    // Remove it from the connection map
    _connections.erase(connection_entry);

    // Notify the handler
    handler("");
}


void gib::IPCConnectionManager::listen_async(
    const std::string & path,
    std::function<void(std::int32_t, const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Create the listener
    asio::local::stream_protocol::acceptor listener(_io_service);

    // There is no asynchronous form for the methods used here, but they should
    // all succeed/fail instantly

    // Try to initialize the listener, cleaning up if initialization fails
    bool opened = false;
    bool bound = false;
    try {
        // Open the listener
        listener.open();
        opened = true;

        // Bind the listener
        listener.bind(asio::local::stream_protocol::endpoint(path));
        bound = true;

        // Start listening
        listener.listen();
    } catch (const asio::system_error & e) {
        // Close the listener if it is open
        if (opened) {
            listener.close();
        }

        // Remove its endpoint if it is bound (if it isn't bound, it may have
        // failed because it is in use by another process)
        if (bound) {
            unlink(path.c_str());
        }

        // Notify the handler
        handler(-1, e.what());

        // Bail
        return;
    }

    // Compute the next listener id.  Just to be paranoid, make sure we don't
    // overflow the maximum value, because we use -1 as the invalid identifier.
    if (_next_listener_id < 0) {
        listener.close();
        unlink(path.c_str());
        handler(-1, "listener ids exhausted");
        return;
    }
    std::int32_t listener_id = _next_listener_id++;

    // Store the listener
    _listeners.emplace(
        std::piecewise_construct,
        std::forward_as_tuple(listener_id),
        std::forward_as_tuple(std::move(listener))
    );

    // Store the endpoint for later cleanup
    _listener_endpoints[listener_id] = path;

    // Notify the handler
    handler(listener_id, "");
}


void gib::IPCConnectionManager::listener_accept_async(
    std::int32_t listener_id,
    std::function<void(std::int32_t, const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Verify that the listener exists
    auto listener_entry = _listeners.find(listener_id);
    if (listener_entry == _listeners.end()) {
        // Call the handler with the error
        handler(-1, "invalid listener id");

        // Bail
        return;
    }

    // Compute the next connection id.  Watch for overflow, because we use -1 as
    // the invalid identifier.
    if (_next_connection_id < 0) {
        handler(-1, "connection ids exhausted");
        return;
    }
    std::int32_t connection_id = _next_connection_id++;

    // Create the socket that will represent the accepted connection
    // TODO: If we move to C++14 (and get generalized lambda captures), it'd be
    // nice to create the connection and then add it to the connection map after
    // accepting has succeeded (that way we don't have to do an add/remove and
    // burn a connection id for failed accept).  But sockets are non-copyable,
    // and we don't have a way to std::move them into the handler lambda, so for
    // now we have to create them in-place to support asynchronous operations.
    _connections.emplace(
        std::piecewise_construct,
        std::forward_as_tuple(connection_id),
        std::forward_as_tuple(_io_service)
    );

    // Accept asynchronously
    listener_entry->second.async_accept(
        _connections.find(connection_id)->second,
        [this, connection_id, handler](const asio::error_code & error) {
            // Check for an error
            std::string error_message = "";
            if (error) {
                // Lock the maps
                // NOTE: This is safe to do in our handler because asio
                // guarantees it never calls handlers from inside the caller
                // (which in our case already holds the lock and would deadlock
                // if we tried to lock again).  We could switch to a recursive
                // mutex, but it's not worth the performance drop.
                std::lock_guard<std::mutex> lock(_lock);

                // Erase the connection
                // NOTE: Don't do this with a captured iterator because it could
                // become invalidated before this handler is invoked
                _connections.erase(connection_id);

                // Notify the handler of the error
                handler(-1, error.message());
            } else {
                // Notify the handler of success
                handler(connection_id, "");
            }
        }
    );
}


void gib::IPCConnectionManager::listener_close_async(
    std::int32_t listener_id,
    std::function<void(const std::string &)> handler
) {
    // Lock the maps
    std::lock_guard<std::mutex> lock(_lock);

    // Verify that the listener exists
    auto listener_entry = _listeners.find(listener_id);
    if (listener_entry == _listeners.end()) {
        handler("invalid listener id");
    }

    // There is no asynchronous close method for listeners, so just close it
    listener_entry->second.close();

    // Remove it from the listener map
    _listeners.erase(listener_entry);

    // Get the listener path
    auto listener_endpoint_entry = _listener_endpoints.find(listener_id);
    if (listener_endpoint_entry == _listener_endpoints.end()) {
        // Listeners and their endpoints should always exist in both maps, this
        // is an internal problem and should be treated as an exception
        throw std::runtime_error("listener endpoint record missing");
    }

    // Remove the listener endpoint from disk
    unlink(listener_endpoint_entry->second.c_str());

    // Remove it from listener endpoint map
    _listener_endpoints.erase(listener_endpoint_entry);

    // Notify the handler
    handler("");
}
