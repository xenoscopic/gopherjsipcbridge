#import "NSData+GIB.h"


@implementation NSData (GIB)

- (NSString *)base64EncodedString {
    return [self base64EncodedStringWithOptions:0];
}

@end
