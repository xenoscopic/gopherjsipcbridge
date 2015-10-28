#import "GIBConnectionManager.h"

// GopherJSIPCBridge includes
#include "gib_connection_manager_posix.h"


@interface GIBConnectionManager ()

@property (strong, nonatomic) dispatch_queue_t dispatchQueue;
// NOTE: We use a direct pointer that we manually deallocate because using an
// instance variable to manage lifetime (e.g. a std::unique_ptr) requires that
// -fobjc-call-cxx-cdtors be passed to the compiler:
// http://stackoverflow.com/a/5090029
@property (assign, nonatomic) gib::ConnectionManagerPosix *connectionManager;

@end


// TODO: We can probably use direct ivar access in here for performance.  Worth
// testing anyway.
@implementation GIBConnectionManager

- (instancetype)init {
    // Call the more general initializer
    return [self initWithHandlerDispatchQueue:dispatch_get_main_queue()];
}

- (instancetype)initWithHandlerDispatchQueue:(dispatch_queue_t)dispatchQueue {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Store the dispatch queue
    self.dispatchQueue = dispatchQueue;

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
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

    // Dispatch the request with a wrapper handler
    self.connectionManager->connect_async(
        [path UTF8String],
        [queue, handler](std::int32_t connectionId, const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler([NSNumber numberWithInt:connectionId], errCocoa);
            });
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
        // Call the Objective-C handler on the dispatch queue
        dispatch_async(self.dispatchQueue, ^{
            handler([NSData data], @"read buffer allocation failed");
        });

        // Bail
        return;
    }

    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

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
        [queue, handler, buffer](std::size_t count, const std::string & error) {
            // Truncate the buffer to the length read
            [buffer replaceBytesInRange:NSMakeRange(count,
                                                    buffer.length - count)
                              withBytes:NULL
                                 length:0];

            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler(buffer, errCocoa);
            });
        }
    );
}

- (void)connectionWriteAsync:(NSNumber *)connectionId
                        data:(NSData *)data
                     handler:(void (^)(NSNumber *, NSString *))handler {
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

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
        [queue, data, handler](std::size_t count, const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler([NSNumber numberWithUnsignedInteger:count], errCocoa);
            });
        }
    );
}

- (void)connectionCloseAsync:(NSNumber *)connectionId
                     handler:(void (^)(NSString *))handler {
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

    // Dispatch the request with a wrapper handler
    self.connectionManager->connection_close_async(
        [connectionId intValue],
        [queue, handler](const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler(errCocoa);
            });
        }
    );
}

- (void)listenAsync:(NSString *)path
            handler:(void (^)(NSNumber *, NSString *))handler {
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

    // Dispatch the request with a wrapper handler
    self.connectionManager->listen_async(
        [path UTF8String],
        [queue, handler](std::int32_t listenerId, const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler([NSNumber numberWithInt:listenerId], errCocoa);
            });
        }
    );
}

- (void)listenerAcceptAsync:(NSNumber *)listenerId
                    handler:(void (^)(NSNumber *, NSString *))handler {
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

    // Dispatch the request with a wrapper handler
    self.connectionManager->listener_accept_async(
        [listenerId intValue],
        [queue, handler](std::int32_t connectionId, const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler([NSNumber numberWithInt:connectionId], errCocoa);
            });
        }
    );
}

- (void)listenerCloseAsync:(NSNumber *)listenerId
                   handler:(void (^)(NSString *))handler {
    // Get dispatch queue
    dispatch_queue_t queue = self.dispatchQueue;

    // Dispatch the request with a wrapper handler
    self.connectionManager->listener_close_async(
        [listenerId intValue],
        [queue, handler](const std::string & error) {
            // Convert the error since it is a reference and may not exist when
            // the handler is invoked
            NSString *errCocoa = [NSString stringWithUTF8String:error.c_str()];

            // Call the Objective-C handler on the dispatch queue
            dispatch_async(queue, ^{
                handler(errCocoa);
            });
        }
    );
}

@end
