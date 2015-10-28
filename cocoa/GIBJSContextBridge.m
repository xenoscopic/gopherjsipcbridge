#import "GIBJSContextBridge.h"

// GopherJS IPC Bridge imports
#import "GIBConnectionManager.h"
#import "NSString+GIB.h"
#import "NSData+GIB.h"


// The JSExport protocol implemented by the proxy object used by
// GIBJSContextBridge
@protocol GIBJSContextBridgeProxyExports <JSExport>

@required

// NOTE: All callbacks in this interface are done using JSValue.  According to
// the JSExport documentation, one should be able to use blocks instead (if all
// callback block arguments are of supported type), however, this doesn't seem
// to work.  I don't know if it's because JSExport's documentation is wrong (I
// suspect this is the case) or because we are trying to pass GopherJS functions
// as callbacks (which should be fine since they are JavaScript functions).  In
// any case, using JSValue seems to work fine, so we'll go with that.  Don't
// waste your time thinking you can make blocks work.

// Bridge method for asynchronously connecting
- (void)connect:(NSString *)endpoint withCallback:(JSValue *)callback;

// Bridge method for asynchronously reading from a connection
- (void)connectionRead:(NSNumber *)connectionId
            withLength:(NSNumber *)length
          withCallback:(JSValue *)callback;

// Bridge method for asynchronously writing to a connection
- (void)connectionWrite:(NSNumber *)connectionId
               withData:(NSString *)data64
           withCallback:(JSValue *)callback;

// Bridge method for asynchronously closing a connection
- (void)connectionClose:(NSNumber *)connectionId
           withCallback:(JSValue *)callback;

// Bridge method for asynchronously starting a listener
- (void)listen:(NSString *)endpoint withCallback:(JSValue *)callback;

// Bridge method for asynchronously accepting from a listener
- (void)listenerAccept:(NSNumber *)listenerId withCallback:(JSValue *)callback;

// Bridge method for asynchronously closing a listener
- (void)listenerClose:(NSNumber *)listenerId withCallback:(JSValue *)callback;

@end


// The proxy object used by GIBJSContextBridge.  We could implement this
// protocol directly in GIBJSContextBridge, but then we'd have to expose the
// protocol publicly and we'd have problems with retain cycles between the
// JSContext and the bridge.
@interface GIBJSContextBridgeProxy : NSObject <GIBJSContextBridgeProxyExports>

// The underlying connection manager
@property (nonatomic) GIBConnectionManager *connectionManager;

// Designated initializer
- (instancetype)initWithInteractionQueue:(dispatch_queue_t)queue;

@end


@implementation GIBJSContextBridgeProxy

- (instancetype)initWithInteractionQueue:(dispatch_queue_t)queue {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager
    self.connectionManager =
        [[GIBConnectionManager alloc] initWithHandlerDispatchQueue:queue];

    // All done
    return self;
}

- (void)connect:(NSString *)endpoint withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectAsync:endpoint
                                 handler:^(NSNumber *connectionId,
                                           NSString *error) {
        [callback callWithArguments:@[connectionId, error]];
    }];
}

- (void)connectionRead:(NSNumber *)connectionId
            withLength:(NSNumber *)length
          withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager
     connectionReadAsync:connectionId
                  length:length
                 handler:^(NSData *data, NSString *error) {
        [callback callWithArguments:@[[data base64EncodedString], error]];
    }];
}

- (void)connectionWrite:(NSNumber *)connectionId
               withData:(NSString *)data64
           withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionWriteAsync:connectionId
                                            data:[data64 base64DecodeBytes]
                                         handler:^(NSNumber *count,
                                                   NSString *error) {
        [callback callWithArguments:@[count, error]];
    }];
}

- (void)connectionClose:(NSNumber *)connectionId
           withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionCloseAsync:connectionId
                                         handler:^(NSString *error) {
        [callback callWithArguments:@[error]];
    }];
}

- (void)listen:(NSString *)endpoint
  withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenAsync:endpoint
                                handler:^(NSNumber *listenerId,
                                          NSString *error) {
        [callback callWithArguments:@[listenerId, error]];
    }];
}

- (void)listenerAccept:(NSNumber *)listenerId
          withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenerAcceptAsync:listenerId
                                        handler:^(NSNumber *connectionId,
                                                  NSString *error) {
        [callback callWithArguments:@[connectionId, error]];
    }];
}

- (void)listenerClose:(NSNumber *)listenerId
         withCallback:(JSValue *)callback {
    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenerCloseAsync:listenerId
                                       handler:^(NSString *error) {
        [callback callWithArguments:@[error]];
    }];
}

@end


@implementation GIBJSContextBridge

- (instancetype)initWithJSContext:(JSContext *)context
                 interactionQueue:(dispatch_queue_t)queue
            initializationMessage:(NSString *)initializationMessage {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the proxy
    GIBJSContextBridgeProxy *proxy =
        [[GIBJSContextBridgeProxy alloc] initWithInteractionQueue:queue];

    // Install the proxy
    [context[@"_GIBJSContextBridgeInitialize"]
     callWithArguments:@[proxy, initializationMessage]];

    // All done
    return self;
}

@end
