#include "gib_connection_manager.h"


gib::ConnectionManager::ConnectionManager() :
_io_service(),
_io_service_pump([this]() {
    // Create a work object to keep the I/O service loop from exiting when there
    // are no pending requests
    asio::io_service::work idle(_io_service);

    // Process I/O requests
    _io_service.run();
}) {

}


gib::ConnectionManager::~ConnectionManager() {
    // Cancel the run loop being executed in the pump thread (this cancels the
    // work object as well, allowing the run() call to return)
    _io_service.stop();

    // Wait for the pump thread to die
    // NOTE: Should technically catch around this, but all errors here should
    // really be fatal enough to call abort anyway
    _io_service_pump.join();
}
