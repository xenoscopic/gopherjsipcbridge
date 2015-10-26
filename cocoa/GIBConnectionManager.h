// Foundation imports
#import <Foundation/Foundation.h>


// Thin wrapper around the C++ ConnectionManager class that translates between
// C++ types and Cocoa types.
@interface GIBConnectionManager : NSObject

// Designated initializer
- (instancetype)init;

// Asynchronously create a new connection
- (void)connectAsync:(NSString *)path
             handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously read from a connection
- (void)connectionReadAsync:(NSNumber *)connectionId
                     length:(NSNumber *)length
                    handler:(void (^)(NSData *, NSString *))handler;

// Asynchronously write to a connection
- (void)connectionWriteAsync:(NSNumber *)connectionId
                        data:(NSData *)data
                     handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously close a connection
- (void)connectionCloseAsync:(NSNumber *)connectionId
                     handler:(void (^)(NSString *))handler;

// Asynchronously begin listening
- (void)listenAsync:(NSString *)path
            handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously accept a connection
- (void)listenerAcceptAsync:(NSNumber *)listenerId
                    handler:(void (^)(NSNumber *, NSString *))handler;

// Asynchronously close a listener
- (void)listenerCloseAsync:(NSNumber *)listenerId
                   handler:(void (^)(NSString *))handler;

@end
