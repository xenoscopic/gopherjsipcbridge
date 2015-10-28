// Foundation imports
#import <Foundation/Foundation.h>

// WebKit imports
#import <WebKit/WebKit.h>


@interface GIBWebViewBridge : NSObject

- (instancetype)initWithWebView:(WebView *)webView
          initializationMessage:(NSString *)initializationMessage;

@end
