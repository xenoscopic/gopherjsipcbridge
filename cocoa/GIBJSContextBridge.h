// Foundation imports
#import <Foundation/Foundation.h>

// JavaScriptCore imports
#import <JavaScriptCore/JavaScriptCore.h>


// Bridge implementation for JavaScriptCore JSContext environments
@interface GIBJSContextBridge : NSObject

// Designated initializer.  Creates a new GIBJSContextBridge connected to the
// specified context.  The interaction queue should be set to a dispatch queue
// where operations can be safely performed on the JSContext.  For example,
// JSContext instances that are part of WebKit WebViews should use
// dispatch_get_main_queue(), because all interaction with web views must happen
// on the main thread.  If you are using a background thread to host a JSContext
// environment, you should create a dispatch queue on that thread and pass it
// here.  The initialization message will be send to the initialization control
// channel in GopherJS.
- (instancetype)initWithJSContext:(JSContext *)context
                 interactionQueue:(dispatch_queue_t)queue
            initializationMessage:(NSString *)initializationMessage;

@end
