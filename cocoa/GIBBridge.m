#import "GIBBridge.h"

// GopherJSIPCBridge imports
#import "GIBConnectionManager.h"
#import "NSString+GIB.h"
#import "NSData+GIB.h"


@interface GIBBridge ()

// Private properties
@property (strong, nonatomic) GIBConnectionManager *connectionManager;

// Private methods
- (void)sendConnectResponse:(NSNumber *)sequence
               connectionId:(NSNumber *)connectionId
                      error:(NSString *)error;
- (void)sendConnectionReadResponse:(NSNumber *)sequence
                              data:(NSData *)data
                             error:(NSString *)error;
- (void)sendConnectionWriteResponse:(NSNumber *)sequence
                              count:(NSNumber *)count
                              error:(NSString *)error;
- (void)sendConnectionCloseResponse:(NSNumber *)sequence
                              error:(NSString *)error;
- (void)sendListenResponse:(NSNumber *)sequence
                listenerId:(NSNumber *)listenerId
                     error:(NSString *)error;
- (void)sendListenerAcceptResponse:(NSNumber *)sequence
                      connectionId:(NSNumber *)connectionId
                             error:(NSString *)error;
- (void)sendListenerCloseResponse:(NSNumber *)sequence
                            error:(NSString *)error;

@end


@implementation GIBBridge

- (instancetype)init {
    // Call the superclass initializer
    if ((self = [super init]) == nil) {
        return nil;
    }

    // Create the connection manager
    self.connectionManager = [[GIBConnectionManager alloc] init];

    // All done
    return self;
}

- (void)sendMessage:(NSString *)message {
    // Base64-encode message
    NSString *messageBase64 = [message base64EncodedString];

    // Invoke the message acceptor
    [self _callPath:@[@"_GIBBridge", @"SendControlMessage"]
      withArguments:@[messageBase64]];
}

- (void)_callPath:(NSArray<NSString *> *)path
    withArguments:(NSArray *)arguments {
    [NSException raise:NSInternalInconsistencyException
                format:@"invocation of abstract method"];
}

- (void)_handleConnectRequest:(NSNumber *)sequence
                   pathBase64:(NSString *)pathBase64 {
    // Decode path
    NSString *path = [pathBase64 base64DecodeString];

    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     connectAsync:path
     handler:^(NSNumber *connectionId,
               NSString *error) {
         // Send a response when the connection manager is done
         [weakSelf sendConnectResponse:sequence
                          connectionId:connectionId
                                 error:error];
     }];
}

- (void)_handleConnectionReadRequest:(NSNumber *)sequence
                        connectionId:(NSNumber *)connectionId
                              length:(NSNumber *)length {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     connectionReadAsync:connectionId
     length:length
     handler:^(NSData *data, NSString *error) {
         // Send a response when the connection manager is done
         [weakSelf sendConnectionReadResponse:sequence
                                         data:data
                                        error:error];
     }];
}

- (void)_handleConnectionWriteRequest:(NSNumber *)sequence
                         connectionId:(NSNumber *)connectionId
                           dataBase64:(NSString *)dataBase64 {
    // Decode the data
    NSData *data = [dataBase64 base64DecodeBytes];

    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     connectionWriteAsync:connectionId
     data:data
     handler:^(NSNumber *count, NSString *error) {
         // Send a response when the connection manager is done
         [weakSelf sendConnectionWriteResponse:sequence
                                         count:count
                                         error:error];
     }];
}

- (void)_handleConnectionCloseRequest:(NSNumber *)sequence
                         connectionId:(NSNumber *)connectionId {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     connectionCloseAsync:connectionId
     handler:^(NSString * error) {
         // Send a response when the connection manager is done
         [weakSelf sendConnectionCloseResponse:sequence error:error];
     }];
}

- (void)_handleListenRequest:(NSNumber *)sequence
                  pathBase64:(NSString *)pathBase64 {
    // Decode path
    NSString *path = [pathBase64 base64DecodeString];

    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     listenAsync:path
     handler:^(NSNumber *listenerId,
               NSString *error) {
         // Send a response when the connection manager is done
         [weakSelf sendListenResponse:sequence
                           listenerId:listenerId
                                error:error];
     }];
}

- (void)_handleListenerAcceptRequest:(NSNumber *)sequence
                          listenerId:(NSNumber *)listenerId {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     listenerAcceptAsync:listenerId
     handler:^(NSNumber *connectionId, NSString *error) {
         // Send a response when the connection manager is done
         [weakSelf sendListenerAcceptResponse:sequence
                                 connectionId:connectionId
                                        error:error];
     }];
}

- (void)_handleListenerCloseRequest:(NSNumber *)sequence
                         listenerId:(NSNumber *)listenerId {
    // Get a weak reference to self to avoid retain cycles
    __weak GIBBridge *weakSelf = self;

    // Dispatch the request to the connection manager
    [self.connectionManager
     listenerCloseAsync:listenerId
     handler:^(NSString * error) {
         // Send a response when the connection manager is done
         [weakSelf sendListenerCloseResponse:sequence
                                       error:error];
     }];
}

- (void)sendConnectResponse:(NSNumber *)sequence
               connectionId:(NSNumber *)connectionId
                      error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondConnect"]
      withArguments:@[sequence, connectionId, errorBase64]];
}

- (void)sendConnectionReadResponse:(NSNumber *)sequence
                              data:(NSData *)data
                             error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Base64-encode data
    NSString *dataBase64 = [data base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondConnectionRead"]
      withArguments:@[sequence, dataBase64, errorBase64]];
}

- (void)sendConnectionWriteResponse:(NSNumber *)sequence
                              count:(NSNumber *)count
                              error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondConnectionWrite"]
      withArguments:@[sequence, count, errorBase64]];
}

- (void)sendConnectionCloseResponse:(NSNumber *)sequence
                              error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondConnectionClose"]
      withArguments:@[sequence, errorBase64]];
}

- (void)sendListenResponse:(NSNumber *)sequence
                listenerId:(NSNumber *)listenerId
                     error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondListen"]
      withArguments:@[sequence, listenerId, errorBase64]];
}

- (void)sendListenerAcceptResponse:(NSNumber *)sequence
                      connectionId:(NSNumber *)connectionId
                             error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondListenerAccept"]
      withArguments:@[sequence, connectionId, errorBase64]];
}

- (void)sendListenerCloseResponse:(NSNumber *)sequence
                            error:(NSString *)error {
    // Base64-encode error
    NSString *errorBase64 = [error base64EncodedString];

    // Invoke the response acceptor
    [self _callPath:@[@"_GIBBridge", @"RespondListenerClose"]
      withArguments:@[sequence, errorBase64]];
}

@end
