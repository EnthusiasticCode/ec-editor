//
//  ECCodeScope.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

@implementation TMScope

@synthesize identifier = _identifier;
@synthesize location = _location;
@synthesize length = _length;
@synthesize parent = _parent;
@synthesize children = _children;

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _children = [NSMutableArray array];
    return self;
}

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier
{
    ECASSERT(identifier);
    TMScope *childScope = [[[self class] alloc] init];
    childScope.identifier = identifier;
    childScope.parent = self;
    [self.children addObject:childScope];
    return childScope;
}

@end
