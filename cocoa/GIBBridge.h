// Foundation imports
#import <Foundation/Foundation.h>


// Abstract base class for all Cocoa GopherJS IPC bridges.  This class cannot be
// used directly.  Use the appropriate GIBBridge subclass suitable for your
// JavaScript environment.
@interface GIBBridge : NSObject

// Designated initializer
- (instancetype)init;

// Messaging methods
- (void)sendMessage:(NSString *)message;

// JavaScript interface methods.  These must be implemented by subclasses.  They
// must not be called by users.  They are exposed only because Objective-C lacks
// a pattern for pure abstract base classes with protected methods.

// Calls the JavaScript function at the specified path with the specified
// arguments.  Arguments will be either NSNumber or NSString instances.  If an
// environment needs to express argument values as literals in order to perform
// the execution, it should treat all NSNumber instances as signed 32-bit
// integers and all NSString instances as base64-encoded strings (which don't
// require escaping).  This method may be called from any thread, and WILL be
// called from threads other than the main one, so environments should ensure
// that calls are dispatched to appropriate threads as necessary.
- (void)_callPath:(NSArray<NSString *> *)path
    withArguments:(NSArray *)arguments;

// Protected methods for subclasses.  These must not be called by users.  They
// are exposed only because Objective-C lacks a pattern for protected methods.

// Handles a connect request
- (void)_handleConnectRequest:(NSNumber *)sequence
                   pathBase64:(NSString *)pathBase64;

// Handles a connection read request
- (void)_handleConnectionReadRequest:(NSNumber *)sequence
                        connectionId:(NSNumber *)connectionId
                              length:(NSNumber *)length;

// Handles a connection write request
- (void)_handleConnectionWriteRequest:(NSNumber *)sequence
                         connectionId:(NSNumber *)connectionId
                           dataBase64:(NSString *)dataBase64;

// Handles a connection close request
- (void)_handleConnectionCloseRequest:(NSNumber *)sequence
                         connectionId:(NSNumber *)connectionId;

// Handles a listen request
- (void)_handleListenRequest:(NSNumber *)sequence
                  pathBase64:(NSString *)pathBase64;

// Handles a listener accept request
- (void)_handleListenerAcceptRequest:(NSNumber *)sequence
                          listenerId:(NSNumber *)listenerId;

// Handles a connection close request
- (void)_handleListenerCloseRequest:(NSNumber *)sequence
                         listenerId:(NSNumber *)listenerId;

@end
