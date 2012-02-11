//
//  CStringCachingString.m
//  ArtCode
//
//  Created by Uri Baghin on 2/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CStringCachingString.h"
#import <objc/runtime.h>

@interface CStringCachingString ()
{
    NSString *_string;
    NSStringEncoding _cachedEncoding;
    const char * _cachedCString;
}
@end

@implementation CStringCachingString

+ (void)load
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    // Docs advise not to call this method, I say docs can shut up (and will probably be proved wrong eventually)
    class_setSuperclass([CStringCachingString class], [NSObject class]);
#pragma clang diagnostic pop
}

+ (BOOL)resolveClassMethod:(SEL)sel
{
    Method method = class_getClassMethod([NSString class], sel);
    if (!method)
        return NO;
    Class metaClass = objc_getMetaClass("CStringCachingString");
    class_addMethod(metaClass, sel, method_getImplementation(method), method_getTypeEncoding(method));
    return YES;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    if (!_string)
        _string = [NSString alloc];
    const char *selectorName = sel_getName(aSelector);
    if (strncmp(selectorName, "init", 4) == 0)
        return self;
    return _string;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    ECASSERT(_string);
    return [_string methodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    ECASSERT(_string);
    ECASSERT([NSStringFromSelector([anInvocation selector]) hasPrefix:@"init"]);
    [anInvocation invokeWithTarget:_string];
    [anInvocation getReturnValue:&_string];
    [anInvocation setReturnValue:(void *)&self];
}

- (const char *)cStringUsingEncoding:(NSStringEncoding)encoding
{
    if (_cachedCString)
        if (_cachedEncoding == encoding)
            return _cachedCString;
        else
            return [_string cStringUsingEncoding:encoding];
    if (!_string)
        return NULL;
    _cachedCString = [_string cStringUsingEncoding:encoding];
    _cachedEncoding = encoding;
    return _cachedCString;
}

@end
