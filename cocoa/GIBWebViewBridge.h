// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>

// GopherJSIPCBridge imports
#import "GIBBridge.h"


@interface GIBWebViewBridge : GIBBridge

- (instancetype)initWithWebView:(WebView *)webView;

@end
