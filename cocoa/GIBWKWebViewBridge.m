#import "GIBWKWebViewBridge.h"


@interface GIBWKWebViewBridge ()

// Private properties
@property (strong, nonatomic) WKWebView *webView;

@end


@implementation GIBWKWebViewBridge

- (instancetype)initWithWKWebView:(WKWebView *)webView {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Store the web view
    self.webView = webView;

    // Install ourselves as a message handler (we can use direct callbacks since
    // the underlying JavaScript engine is out-of-process, so we have to use
    // this somewhat annoying messaging framework).  These message handlers
    // exist in JavaScript at window.webkit.messageHandlers.NAME.postMessage.
    // Any messages posted get sent to the
    // userContentController:didReceiveScriptMessage delegate method below.
    // Unfortunately, the messages can only contain a single object argument, so
    // we have to provide some shims that GopherJS can call into.
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBConnect"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBConnectionRead"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBConnectionWrite"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBConnectionClose"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBListen"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBListenerAccept"];
    [self.webView.configuration.userContentController
     addScriptMessageHandler:self
     name:@"GIBListenerClose"];

    // Install JavaScript shim handlers for GopherJS to call
    // TODO: Add load error checking?
    NSString *shimPath =
        [[NSBundle mainBundle] pathForResource:@"GIBWKWebViewBridge"
                                        ofType:@"js"];
    NSString *shimCode = [NSString stringWithContentsOfFile:shimPath
                                                   encoding:NSUTF8StringEncoding
                                                      error:NULL];
    [self.webView evaluateJavaScript:shimCode completionHandler:nil];

    // All done
    return self;
}

- (void)shutdown {
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBConnect"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBConnectionRead"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBConnectionWrite"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBConnectionClose"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBListen"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBListenerAccept"];
    [self.webView.configuration.userContentController
     removeScriptMessageHandlerForName:@"GIBListenerClose"];
}

- (void)_callPath:(NSArray<NSString *> *)path
    withArguments:(NSArray *)arguments {
    // Create the call
    // TODO: Calculate a better estimation of capacity
    NSMutableString *call = [NSMutableString stringWithCapacity:0];

    // Add the target name and opening parenthesis
    [call appendFormat:@"%@(", [path componentsJoinedByString:@"."]];

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

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    // Extract the message name
    NSString *name = message.name;

    // Extract the message body
    NSDictionary *body = message.body;

    // Extract sequence
    NSNumber *sequence = body[@"sequence"];

    // Switch based on the message name
    if ([name isEqualToString:@"GIBConnect"]) {
        // Extract remaining arguments
        NSString *pathBase64 = body[@"pathBase64"];

        // Handle the request
        [self _handleConnectRequest:sequence pathBase64:pathBase64];
    } else if ([name isEqualToString:@"GIBConnectionRead"]) {
        // Extract remaining arguments
        NSNumber *connectionId = body[@"connectionId"];
        NSNumber *length = body[@"length"];

        // Handle the request
        [self _handleConnectionReadRequest:sequence
                              connectionId:connectionId
                                    length:length];
    } else if ([name isEqualToString:@"GIBConnectionWrite"]) {
        // Extract remaining arguments
        NSNumber *connectionId = body[@"connectionId"];
        NSString *dataBase64 = body[@"dataBase64"];

        // Handle the request
        [self _handleConnectionWriteRequest:sequence
                               connectionId:connectionId
                                 dataBase64:dataBase64];
    } else if ([name isEqualToString:@"GIBConnectionClose"]) {
        // Extract remaining arguments
        NSNumber *connectionId = body[@"connectionId"];

        // Handle the request
        [self _handleConnectionCloseRequest:sequence connectionId:connectionId];
    } else if ([name isEqualToString:@"GIBListen"]) {
        // Extract remaining arguments
        NSString *pathBase64 = body[@"pathBase64"];

        // Handle the request
        [self _handleListenRequest:sequence pathBase64:pathBase64];
    } else if ([name isEqualToString:@"GIBListenerAccept"]) {
        // Extract remaining arguments
        NSNumber *listenerId = body[@"listenerId"];

        // Handle the request
        [self _handleListenerAcceptRequest:sequence listenerId:listenerId];
    } else if ([name isEqualToString:@"GIBListenerClose"]) {
        // Extract remaining arguments
        NSNumber *listenerId = body[@"listenerId"];

        // Handle the request
        [self _handleListenerCloseRequest:sequence listenerId:listenerId];
    }
}

@end
