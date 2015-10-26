#import "GIBWebViewBridge.h"

// JavaScriptCore imports
#import <JavaScriptCore/JavaScriptCore.h>


@interface GIBWebViewBridge ()

// Private properties
// NOTE: This needs to be strong, otherwise the JSContext returned by
// contextWithJSGlobalContextRef: doesn't seem to be retained (by anything).  I
// think that contextWithJSGlobalContextRef: simply returns a proxy object to
// the JSGlobalContextRef it's provided with, so while the underlying
// JSGlobalContextRef remains alive, the proxy object seems to die, or at least
// that's my best guess.
@property (strong, nonatomic) JSContext *jsContext;

@end


@implementation GIBWebViewBridge

- (instancetype)initWithWebView:(WebView *)webView {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Extract and store the webview's JavaScript context
    // NOTE: See note for this property about strong retention
    self.jsContext =
        [JSContext
         contextWithJSGlobalContextRef:[[webView mainFrame] globalContext]];

    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Install connect handler
    void (^connectHandler)(NSNumber *, NSString *) =
        ^(NSNumber *sequence, NSString *pathBase64) {
            [weakSelf _handleConnectRequest:sequence pathBase64:pathBase64];
        };
    [self _callPath:@[@"_GIBBridge", @"SetConnectHandler"]
      withArguments:@[connectHandler]];

    // Install connection read handler
    void (^connectionReadHandler)(NSNumber *, NSNumber *, NSNumber *) =
        ^(NSNumber *sequence, NSNumber *connectionId, NSNumber *length) {
            [weakSelf _handleConnectionReadRequest:sequence
                                      connectionId:connectionId
                                            length:length];
        };
    [self _callPath:@[@"_GIBBridge", @"SetConnectionReadHandler"]
      withArguments:@[connectionReadHandler]];

    // Install connection write handler
    void (^connectionWriteHandler)(NSNumber *, NSNumber *, NSString *) =
        ^(NSNumber *sequence, NSNumber *connectionId, NSString *dataBase64) {
            [weakSelf _handleConnectionWriteRequest:sequence
                                       connectionId:connectionId
                                         dataBase64:dataBase64];
        };
    [self _callPath:@[@"_GIBBridge", @"SetConnectionWriteHandler"]
      withArguments:@[connectionWriteHandler]];

    // Install connection close handler
    void (^connectionCloseHandler)(NSNumber *, NSNumber *) =
        ^(NSNumber *sequence, NSNumber *connectionId) {
            [weakSelf _handleConnectionCloseRequest:sequence
                                       connectionId:connectionId];
        };
    [self _callPath:@[@"_GIBBridge", @"SetConnectionCloseHandler"]
      withArguments:@[connectionCloseHandler]];

    // Install listen handler
    void (^listenHandler)(NSNumber *, NSString *) =
        ^(NSNumber *sequence, NSString *pathBase64) {
            [weakSelf _handleListenRequest:sequence pathBase64:pathBase64];
        };
    [self _callPath:@[@"_GIBBridge", @"SetListenHandler"]
      withArguments:@[listenHandler]];

    // Install listener accept handler
    void (^listenerAcceptHandler)(NSNumber *, NSNumber *) =
        ^(NSNumber *sequence, NSNumber *listenerId) {
            [weakSelf _handleListenerAcceptRequest:sequence
                                        listenerId:listenerId];
        };
    [self _callPath:@[@"_GIBBridge", @"SetListenerAcceptHandler"]
      withArguments:@[listenerAcceptHandler]];

    // Install listener close handler
    void (^listenerCloseHandler)(NSNumber *, NSNumber *) =
        ^(NSNumber *sequence, NSNumber *listenerId) {
            [weakSelf _handleListenerCloseRequest:sequence
                                       listenerId:listenerId];
        };
    [self _callPath:@[@"_GIBBridge", @"SetListenerCloseHandler"]
      withArguments:@[listenerCloseHandler]];

    // All done
    return self;
}

- (void)_callPath:(NSArray<NSString *> *)path
    withArguments:(NSArray *)arguments {
    // Make sure the path isn't empty
    if (path.count == 0) {
        [NSException raise:NSInvalidArgumentException
                    format:@"empty function path"];
    }

    // Perform all interaction with the context on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // Grab the target function
        JSValue *target = self.jsContext[path[0]];
        for (NSUInteger i = 1; i < path.count; ++i) {
            target = target[path[i]];
        }

        // Invoke the target
        [target callWithArguments:arguments];
    });
}

@end
