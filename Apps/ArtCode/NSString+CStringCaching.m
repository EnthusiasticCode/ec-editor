//
//  NSString+CStringCaching.m
//  ArtCode
//
//  Created by Uri Baghin on 3/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSString+CStringCaching.h"
#import <objc/runtime.h>

@interface CStringCachingString : NSObject {
    NSString *_string;
    NSStringEncoding _cachedEncoding;
    const char * _cachedCString;
}
@end

@implementation NSString (CStringCaching)

- (NSString *)stringByCachingCString {
    return [(NSString *)[CStringCachingString alloc] initWithString:self];
}

@end

@implementation CStringCachingString

+ (BOOL)resolveClassMethod:(SEL)sel {
    Method method = class_getClassMethod([NSString class], sel);
    if (!method) {
        return NO;
    }
    Class metaClass = objc_getMetaClass("CStringCachingString");
    class_addMethod(metaClass, sel, method_getImplementation(method), method_getTypeEncoding(method));
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector {
    if (!_string) {
        _string = [NSString alloc];
    }
    const char *selectorName = sel_getName(aSelector);
    if (strncmp(selectorName, "init", 4) == 0) {
        return nil;
    }
    return _string;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    ASSERT(_string);
    return [_string methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    ASSERT(_string);
    ASSERT([NSStringFromSelector([anInvocation selector]) hasPrefix:@"init"]);
    [anInvocation invokeWithTarget:_string];
    [anInvocation getReturnValue:&_string];
    [anInvocation setReturnValue:(void *)&self];
}

- (const char *)cStringUsingEncoding:(NSStringEncoding)encoding {
    ASSERT(_string);
    if (_cachedCString) {
        if (_cachedEncoding == encoding) {
            return _cachedCString;
        } else {
            return [_string cStringUsingEncoding:encoding];
        }
    }
    _cachedCString = [_string cStringUsingEncoding:encoding];
    _cachedEncoding = encoding;
    return _cachedCString;
}

@end
