// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>

// GopherJS IPC Bridge imports
#import "GIBJSContextBridge.h"


// Bridge implementation for WebKit WebViews
@interface GIBWebViewBridge : GIBJSContextBridge

// Designated initializer.  Creates a new GIBWebViewBridge connected to the
// specified web view.  The initialization message will be send to the
// initialization control channel in GopherJS.
- (instancetype)initWithWebView:(WebView *)webView
          initializationMessage:(NSString *)initializationMessage;

@end
