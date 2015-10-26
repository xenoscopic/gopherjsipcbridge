#import "NSString+GIB.h"

// GopherJSIPCBridge imports
#import "NSData+GIB.h"

@implementation NSString (GIB)

- (NSString *)base64EncodedString {
    return [[self dataUsingEncoding:NSUTF8StringEncoding] base64EncodedString];
}

- (NSData *)base64DecodeBytes {
    return [[NSData alloc] initWithBase64EncodedString:self options:0];
}

- (NSString *)base64DecodeString {
    return [[NSString alloc] initWithData:[self base64DecodeBytes]
                                 encoding:NSUTF8StringEncoding];
}

@end
