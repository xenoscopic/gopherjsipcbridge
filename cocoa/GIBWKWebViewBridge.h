// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>


@interface GIBWKWebViewBridge : NSObject

- (instancetype)initWithWKWebView:(WKWebView *)webView;

- (void)sendMessage:(NSString *)message;

@end
