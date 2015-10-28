#import "GIBWKWebViewBridge.h"

// GopherJS IPC Bridge imports
#import "GIBConnectionManager.h"
#import "NSString+GIB.h"
#import "NSData+GIB.h"


typedef NS_ENUM(NSUInteger, WKWebViewBridgeAction) {
    WKWebViewBridgeActionConnect,
    WKWebViewBridgeActionConnectionRead,
    WKWebViewBridgeActionConnectionWrite,
    WKWebViewBridgeActionConnectionClose,
    WKWebViewBridgeActionListen,
    WKWebViewBridgeActionListenerAccept,
    WKWebViewBridgeActionListenerClose
};


@interface GIBWKWebViewBridge ()

// The underlying connection manager
@property (nonatomic) GIBConnectionManager *connectionManager;

// The target web view, referenced weakly to avoid retain cycles
@property (weak, nonatomic) WKWebView *webView;

// Private methods

// Convenience method for calling JavaScript.  The target argument should be a
// JavaScript string that evaluates to a callable (e.g. x.y.z, which could be
// called x.y.z(...arguments...)).  Arguments should be a sequence of NSString
// or NSNumber values.  NSStrings should not require escaping to be represented
// as string literals.  NSNumbers will be treated as signed integer values when
// converting to literals.  This method should only be invoked from the main
// thread, which is enforced in the class by making the connection manager only
// invoke asynchronous callbacks on the main thread.
- (void)callTarget:(NSString *)target withArguments:(NSArray *)arguments;

// Handler for asynchronously connecting
- (void)connect:(NSString *)endpoint withSequence:(NSNumber *)sequence;

// Handler for asynchronously reading from a connection
- (void)connectionRead:(NSNumber *)connectionId
            withLength:(NSNumber *)length
          withSequence:(NSNumber *)sequence;

// Handler for asynchronously writing to a connection
- (void)connectionWrite:(NSNumber *)connectionId
               withData:(NSString *)data64
           withSequence:(NSNumber *)sequence;

// Handler for asynchronously closing a connection
- (void)connectionClose:(NSNumber *)connectionId
           withSequence:(NSNumber *)sequence;

// Handler for asynchronously starting a listener
- (void)listen:(NSString *)endpoint withSequence:(NSNumber *)sequence;

// Handler for asynchronously accepting from a listener
- (void)listenerAccept:(NSNumber *)listenerId withSequence:(NSNumber *)sequence;

// Handler for asynchronously closing a listener
- (void)listenerClose:(NSNumber *)listenerId withSequence:(NSNumber *)sequence;

@end


@implementation GIBWKWebViewBridge

- (instancetype)initWithWKWebView:(WKWebView *)webView
            initializationMessage:(NSString *)initializationMessage; {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager.  Enforce that all callbacks take place on
    // the main thread (the default if not specified).
    self.connectionManager = [[GIBConnectionManager alloc] init];

    // Store the web view
    self.webView = webView;

    // Install ourselves as the bridge message handler
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"_GIBWKWebViewBridgeMessageHandler"];

    // Invoke the initialization sequence
    [self callTarget:@"_GIBWKWebViewBridgeInitialize"
       withArguments:@[[initializationMessage base64EncodedString]]];

    // All done
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    // Extract message body
    NSDictionary *body = message.body;

    // Extract sequence
    NSNumber *sequence = body[@"sequence"];

    // Extract action
    WKWebViewBridgeAction action =
        [(NSNumber *)body[@"action"] unsignedIntegerValue];

    // Switch based on action
    switch (action) {
        case WKWebViewBridgeActionConnect:
            [self connect:body[@"endpoint"] withSequence:sequence];
            break;
        case WKWebViewBridgeActionConnectionRead:
            [self connectionRead:body[@"connectionId"]
                      withLength:body[@"length"]
                    withSequence:sequence];
            break;
        case WKWebViewBridgeActionConnectionWrite:
            [self connectionWrite:body[@"connectionId"]
                         withData:body[@"data64"]
                     withSequence:sequence];
            break;
        case WKWebViewBridgeActionConnectionClose:
            [self connectionClose:body[@"connectionId"]
                     withSequence:sequence];
            break;
        case WKWebViewBridgeActionListen:
            [self listen:body[@"endpoint"] withSequence:sequence];
            break;
        case WKWebViewBridgeActionListenerAccept:
            [self listenerAccept:body[@"listenerId"] withSequence:sequence];
            break;
        case WKWebViewBridgeActionListenerClose:
            [self listenerClose:body[@"listenerId"] withSequence:sequence];
            break;
        default:
            break;
    }
}

- (void)callTarget:(NSString *)target withArguments:(NSArray *)arguments {
    // Create the call
    // TODO: Calculate a better estimation of capacity
    NSMutableString *call = [NSMutableString stringWithCapacity:0];

    // Add the target name and opening parenthesis
    [call appendFormat:@"%@(", target];

    // Append argument literals and finish the call
    NSUInteger nArguments = [arguments count];
    [arguments enumerateObjectsUsingBlock:^(id obj,
                                            NSUInteger idx,
                                            BOOL * stop) {
        // Add the argument
        if ([obj isKindOfClass:[NSNumber class]]) {
            // If this is a number, it will be a 32-bit integer
            [call appendFormat:@"%d", [(NSNumber *)obj intValue]];
        } else {
            // Otherwise, it must be a string, and it will be base64-encoded, so
            // no escaping is necessary
            [call appendFormat:@"\"%@\"", (NSString *)obj];
        }

        // Add a comma or close the call
        if (idx < (nArguments - 1)) {
            [call appendFormat:@","];
        } else {
            [call appendFormat:@");"];
        }
    }];

    // Perform all interaction with the web view on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:call completionHandler:nil];
    });
}

- (void)connect:(NSString *)endpoint withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectAsync:endpoint
                                 handler:^(NSNumber *connectionId,
                                           NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondConnect"
               withArguments:@[sequence,
                               connectionId,
                               [error base64EncodedString]]];
    }];
}

- (void)connectionRead:(NSNumber *)connectionId
            withLength:(NSNumber *)length
          withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionReadAsync:connectionId
                                         length:length
                                        handler:^(NSData *data,
                                                  NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondConnectionRead"
               withArguments:@[sequence,
                               [data base64EncodedString],
                               [error base64EncodedString]]];
    }];
}

- (void)connectionWrite:(NSNumber *)connectionId
               withData:(NSString *)data64
           withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionWriteAsync:connectionId
                                            data:[data64 base64DecodeBytes]
                                         handler:^(NSNumber *count,
                                                   NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondConnectionWrite"
               withArguments:@[sequence, count, [error base64EncodedString]]];
    }];
}

- (void)connectionClose:(NSNumber *)connectionId
           withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager connectionCloseAsync:connectionId
                                         handler:^(NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondConnectionClose"
               withArguments:@[sequence, [error base64EncodedString]]];
    }];
}

- (void)listen:(NSString *)endpoint withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenAsync:endpoint
                                handler:^(NSNumber *listenerId,
                                          NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondListen"
               withArguments:@[sequence,
                               listenerId,
                               [error base64EncodedString]]];
    }];
}

- (void)listenerAccept:(NSNumber *)listenerId
          withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenerAcceptAsync:listenerId
                                        handler:^(NSNumber *connectionId,
                                                  NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondListenerAccept"
               withArguments:@[sequence,
                               connectionId,
                               [error base64EncodedString]]];
    }];
}

- (void)listenerClose:(NSNumber *)listenerId withSequence:(NSNumber *)sequence {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBWKWebViewBridge *weakSelf = self;

    // Dispatch the request to the connection manager with a callback adapter
    [self.connectionManager listenerCloseAsync:listenerId
                                       handler:^(NSString *error) {
        [weakSelf callTarget:@"_GIBWKWebViewBridge.RespondListenerClose"
               withArguments:@[sequence, [error base64EncodedString]]];
    }];
}

@end
