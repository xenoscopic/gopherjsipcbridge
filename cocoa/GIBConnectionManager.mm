#import "GIBConnectionManager.h"

// GopherJSIPCBridge includes
#include "gib_connection_manager_posix.h"


@interface GIBConnectionManager ()

// NOTE: We use a direct pointer that we manually deallocate because using an
// instance variable to manage lifetime (e.g. a std::unique_ptr) requires that
// -fobjc-call-cxx-cdtors be passed to the compiler:
// http://stackoverflow.com/a/5090029
@property (assign, nonatomic) gib::ConnectionManagerPosix *connectionManager;

@end


@implementation GIBConnectionManager

- (instancetype)init {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager
    self.connectionManager = new gib::ConnectionManagerPosix();

    // All done
    return self;
}

- (void)dealloc {
    // Delete the underlying connection manager.  This will block until all of
    // the connection manager's handlers have been cancelled or (if they are
    // already running) return.  This will also close any open sockets managed
    // by the connection manager.
    delete self.connectionManager;
}

- (void)connectAsync:(NSString *)path
             handler:(void (^)(NSNumber *, NSString *))handler {
    // Dispatch the request with a wrapper handler
    self.connectionManager->connect_async(
        [path UTF8String],
        [handler](std::int32_t connectionId, const std::string & error) {
            // Call the Objective-C handler
            handler([NSNumber numberWithInt:connectionId],
                    [NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)connectionReadAsync:(NSNumber *)connectionId
                     length:(NSNumber *)length
                    handler:(void (^)(NSData *, NSString *))handler {
    // Create a read buffer
    NSMutableData *buffer =
        [NSMutableData dataWithLength:[length unsignedIntegerValue]];

    // Verify that the allocation succeeded
    if (!buffer) {
        // Call the Objective-C handler
        handler([NSData data], @"read buffer allocation failed");
    }

    // Dispatch the request with a wrapper handler
    // NOTE: We capture the buffer in our handler lambda, both because we
    // use it and because we need to keep it alive for the duration of the
    // read.  Apparently Objective-C++'s Automatic Reference Counting is
    // smart enough to "retain" strong values captured into a C++ lambda:
    // http://stackoverflow.com/a/18272212
    // http://stackoverflow.com/a/13129006
    self.connectionManager->connection_read_async(
        [connectionId intValue],
        buffer.mutableBytes,
        buffer.length,
        [handler, buffer](std::size_t count, const std::string & error) {
            // Truncate the buffer to the length read
            [buffer replaceBytesInRange:NSMakeRange(count,
                                                    buffer.length - count)
                              withBytes:NULL
                                 length:0];

            // Call the Objective-C handler
            handler(buffer, [NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)connectionWriteAsync:(NSNumber *)connectionId
                        data:(NSData *)data
                     handler:(void (^)(NSNumber *, NSString *))handler {
    // Dispatch the request with a wrapper handler
    // NOTE: We capture the buffer in our handler lambda, because we need to
    // keep it alive for the duration of the write.  Apparently
    // Objective-C++'s Automatic Reference Counting is smart enough to
    // "retain" strong values captured into a C++ lambda:
    // http://stackoverflow.com/a/18272212
    // http://stackoverflow.com/a/13129006
    // Also, even though we don't use the variable in our handler, it won't
    // be optimized out if EXPLICITLY captured:
    // http://stackoverflow.com/a/12718425
    self.connectionManager->connection_write_async(
        [connectionId intValue],
        data.bytes,
        data.length,
        [data, handler](std::size_t count, const std::string & error) {
            // Call the Objective-C handler
            handler([NSNumber numberWithUnsignedInteger:count],
                    [NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)connectionCloseAsync:(NSNumber *)connectionId
                     handler:(void (^)(NSString *))handler {
    // Dispatch the request with a wrapper handler
    self.connectionManager->connection_close_async(
        [connectionId intValue],
        [handler](const std::string & error) {
            // Call the Objective-C handler
            handler([NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)listenAsync:(NSString *)path
            handler:(void (^)(NSNumber *, NSString *))handler {
    // Dispatch the request with a wrapper handler
    self.connectionManager->listen_async(
        [path UTF8String],
        [handler](std::int32_t listenerId, const std::string & error) {
            // Call the Objective-C handler
            handler([NSNumber numberWithInt:listenerId],
                    [NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)listenerAcceptAsync:(NSNumber *)listenerId
                    handler:(void (^)(NSNumber *, NSString *))handler {
    // Dispatch the request with a wrapper handler
    self.connectionManager->listener_accept_async(
        [listenerId intValue],
        [handler](std::int32_t connectionId, const std::string & error) {
            // Call the Objective-C handler
            handler([NSNumber numberWithInt:connectionId],
                    [NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

- (void)listenerCloseAsync:(NSNumber *)listenerId
                   handler:(void (^)(NSString *))handler {
    // Dispatch the request with a wrapper handler
    self.connectionManager->listener_close_async(
        [listenerId intValue],
        [handler](const std::string & error) {
            // Call the Objective-C handler
            handler([NSString stringWithUTF8String:error.c_str()]);
        }
    );
}

@end
