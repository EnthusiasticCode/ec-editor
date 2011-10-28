//
//  NSObject+FixedAutoContentAccessingProxy.m
//  ECFoundation
//
//  Created by Uri Baghin on 10/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSObject+FixedAutoContentAccessingProxy.h"

@interface ECAutoContentAccessingProxy : NSProxy
{
    @package
    id _target;
}
- (id)forwardingTargetForSelector:(SEL)aSelector;
@end

@implementation ECAutoContentAccessingProxy

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _target;
}

- (void)dealloc
{
    [_target endContentAccess];
}

@end

@implementation NSObject (FixedAutoContentAccessingProxy)

- (id)autoContentAccessingProxy
{
    if (![self respondsToSelector:@selector(beginContentAccess)] || ![self respondsToSelector:@selector(endContentAccess)])
        return self;
    ECAutoContentAccessingProxy *proxy = [ECAutoContentAccessingProxy alloc];
    [(id<NSDiscardableContent>)self beginContentAccess];
    proxy->_target = self;
    return proxy;
}

@end
