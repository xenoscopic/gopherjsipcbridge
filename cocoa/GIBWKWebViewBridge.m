#import "GIBWKWebViewBridge.h"

// GopherJSIPCBridge imports
#import "GIBConnectionManager.h"
#import "NSString+GIB.h"


@interface GIBWKWebViewBridge ()

// Private properties
@property (strong, nonatomic) GIBConnectionManager *connectionManager;
@property (strong, nonatomic) WKWebView *webView;

@end


@implementation GIBWKWebViewBridge

- (instancetype)initWithWKWebView:(WKWebView *)webView {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager
    self.connectionManager = [[GIBConnectionManager alloc] init];

    // Store the webview
    self.webView = webView;

    // TODO: Install request handlers for GopherJS to call

    // All done
    return self;
}

- (void)sendMessage:(NSString *)message {
    // Base64-encode message
    NSString *messageBase64 = [message base64EncodedString];

    // Compute JavaScript
    NSString *code =
        [NSString stringWithFormat:@"_GIBBridge.SendControlMessage('%@');",
         messageBase64];

    // Invoke on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:code
                       completionHandler:nil];
    });
}

@end
