// Foundation imports
#import <Foundation/Foundation.h>


// Thin wrapper around the C++ IPCConnectionManager class that translates
// between C++ types and Cocoa types.  This wrapper additionally allows callers
// to specify the dispatch queue where handlers should be invoked (the C++
// IPCConnectionManager invokes them either in the calling thread or the I/O
// service pump thread).
@interface GIBIPCConnectionManager : NSObject

// Designated initializer.  This will create a connection manager that invokes
// handlers on the main thread.
- (instancetype)init;

// Designated initializer.  This will create a connection manager that invokes
// handlers on the specified dispatch queue.
- (instancetype)initWithHandlerDispatchQueue:(dispatch_queue_t)dispatchQueue;

// Asynchronously create a new connection
- (void)connectAsync:(NSString *)endpoint
             handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously read from a connection
- (void)connectionReadAsync:(NSNumber *)connectionId
                     length:(NSNumber *)length
                    handler:(void (^)(NSData *, NSString *))handler;

// Asynchronously write to a connection
- (void)connectionWriteAsync:(NSNumber *)connectionId
                        data:(NSData *)data
                     handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously close a connection
- (void)connectionCloseAsync:(NSNumber *)connectionId
                     handler:(void (^)(NSString *))handler;

// Asynchronously begin listening
- (void)listenAsync:(NSString *)endpoint
            handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously accept a connection
- (void)listenerAcceptAsync:(NSNumber *)listenerId
                    handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously close a listener
- (void)listenerCloseAsync:(NSNumber *)listenerId
                   handler:(void (^)(NSString *))handler;

@end
