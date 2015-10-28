// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>


@interface GIBWKWebViewBridge : NSObject <WKScriptMessageHandler>

// Designated initializer.  Creates a new GIBWKWebViewBridge connected to the
// specified web view.  The initialization message will be sent to the
// initialization control channel in GopherJS.
- (instancetype)initWithWKWebView:(WKWebView *)webView
            initializationMessage:(NSString *)initializationMessage;

@end
