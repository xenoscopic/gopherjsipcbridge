// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>

// GopherJSIPCBridge imports
#import "GIBBridge.h"


@interface GIBWKWebViewBridge : GIBBridge <WKScriptMessageHandler>

- (instancetype)initWithWKWebView:(WKWebView *)webView;

// The GIBWKWebViewBridge installs message handlers into the WKWebView instance.
// Unfortunately this means that the WKWebView strongly retains the
// GIBWKWebViewBridge.  This removes those handlers, allowing the bridge to be
// released.
- (void)shutdown;

@end
