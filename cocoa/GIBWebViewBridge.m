#import "GIBWebViewBridge.h"

// JavaScriptCore imports
#import <JavaScriptCore/JavaScriptCore.h>

// GopherJS IPC Bridge imports
#import "GIBConnectionManager.h"
#import "NSString+GIB.h"
#import "NSData+GIB.h"


@protocol GIBWebViewBridgeProxyExports <JSExport>

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


@interface GIBWebViewBridgeProxy : NSObject <GIBWebViewBridgeProxyExports>

@property (nonatomic) GIBConnectionManager *connectionManager;

// TODO: If we switch GIBWebViewBridgeProxy to GIBJSContextProxy, allow it to
// take a dispatch queue and pass it to the connection manager.
- (instancetype)init;

@end


@implementation GIBWebViewBridgeProxy

- (instancetype)init {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager
    self.connectionManager = [[GIBConnectionManager alloc] init];

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
        // Base64-encode the data
        NSString *data64 = [data base64EncodedString];

        // Call the callback
        [callback callWithArguments:@[data64, error]];
    }];
}

- (void)connectionWrite:(NSNumber *)connectionId
               withData:(NSString *)data64
           withCallback:(JSValue *)callback {
    // Decode the data
    NSData *data = [data64 base64DecodeBytes];

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionWriteAsync:connectionId
                                            data:data
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


@interface GIBWebViewBridge ()

// Private properties
// NOTE: This needs to be strong, otherwise the JSContext returned by
// contextWithJSGlobalContextRef: doesn't seem to be retained (by anything).  I
// think that contextWithJSGlobalContextRef: simply returns a proxy object to
// the JSGlobalContextRef it's provided with, so while the underlying
// JSGlobalContextRef remains alive, the proxy object seems to die, or at least
// that's my best guess.
@property (strong, nonatomic) JSContext *jsContext;
@property (strong, nonatomic) GIBWebViewBridgeProxy *jsProxy;

@end


@implementation GIBWebViewBridge

- (instancetype)initWithWebView:(WebView *)webView
          initializationMessage:(NSString *)initializationMessage {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // TODO: See if we actually need to retain either of these... I doubt it

    // Extract and store the webview's JavaScript context
    // NOTE: See note for this property about strong retention
    self.jsContext =
        [JSContext
         contextWithJSGlobalContextRef:[[webView mainFrame] globalContext]];

    // Create our proxy
    self.jsProxy = [[GIBWebViewBridgeProxy alloc] init];

    // Install the proxy
    [self.jsContext[@"_GIBJSContextBridgeInitialize"] callWithArguments:@[self.jsProxy, initializationMessage]];

    // All done
    return self;
}

@end
