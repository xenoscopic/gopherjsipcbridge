// Foundation imports
#import <Foundation/Foundation.h>

@interface NSString (GIB)

// Computes the UTF-8-encoded version of the string and generates the
// base64-encoded string representing the UTF-8 bytes
- (NSString *)base64EncodedString;

// Decodes a base64-encoded string to a sequence of bytes
- (NSData *)base64DecodeBytes;

// Decodes a base64-encoded string to a sequence of bytes, which are assumed to
// be UTF-8, and then generates a string from those bytes
- (NSString *)base64DecodeString;

@end
