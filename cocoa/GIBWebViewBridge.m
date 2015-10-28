#import "GIBWebViewBridge.h"

// JavaScriptCore imports
#import <JavaScriptCore/JavaScriptCore.h>


@implementation GIBWebViewBridge

- (instancetype)initWithWebView:(WebView *)webView
          initializationMessage:(NSString *)initializationMessage {
    // Extract the JSContext
    JSContext *context =
        [JSContext
         contextWithJSGlobalContextRef:[[webView mainFrame] globalContext]];

    // Call the superclass initializer
    return [super initWithJSContext:context
                   interactionQueue:dispatch_get_main_queue()
              initializationMessage:initializationMessage];
}

@end
