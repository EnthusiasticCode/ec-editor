//
//  WeakObjectWrapper.m
//  ECFoundation
//
//  Created by Uri Baghin on 1/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "WeakObjectWrapper.h"

@implementation WeakObjectWrapper

+ (WeakObjectWrapper *)wrapperWithObject:(id)object
{
    WeakObjectWrapper *wrapper = [[self alloc] init];
    wrapper->object = object;
    return wrapper;
}

@end
