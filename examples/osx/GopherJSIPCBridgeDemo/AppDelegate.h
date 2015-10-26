// Cocoa imports
#import <Cocoa/Cocoa.h>

// WebKit imports
#import <WebKit/WebKit.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,
                                   WebFrameLoadDelegate,
                                   WKNavigationDelegate>

// WebFrameLoadDelegate methods
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame;

// WKNavigationDelegate methods
- (void)webView:(WKWebView *)webView
didFinishNavigation:(WKNavigation *)navigation;

@end

