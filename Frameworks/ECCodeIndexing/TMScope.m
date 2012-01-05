//
//  ECCodeScope.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 1/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TMScope.h"

@interface TMScope ()
{
    NSMutableArray *_children;
}
@end

@implementation TMScope

@synthesize identifier = _identifier;
@synthesize offset = _offset;
@synthesize length = _length;
@synthesize baseString = _baseString;
@synthesize parent = _parent;

- (NSString *)spelling
{
    return nil;// [self.baseString substringWithRange:NSMakeRange(self.baseOffset, self.length)];
}

+ (NSSet *)keyPathsForValuesAffectingSpelling
{
    return [NSSet setWithObjects:@"baseOffset", @"length", @"baseString", nil];
}

- (NSString *)baseString
{
    if (self.parent)
        return self.parent.baseString;
    return _baseString;
}

- (void)setBaseString:(NSString *)baseString
{
    ECASSERT(!self.parent && "baseString can only be changed for root scopes");
    if (baseString == _baseString)
        return;
    [self willChangeValueForKey:@"baseString"];
    _baseString = baseString;
    [self didChangeValueForKey:@"baseString"];
}

+ (NSSet *)keyPathsForValuesAffectingBaseString
{
    return [NSSet setWithObject:@"parent.baseString"];
}

- (NSUInteger)baseOffset
{
    if (!self.parent)
        return self.offset;
    NSUInteger childIndex = [self.parent.children indexOfObject:self];
    if (!childIndex)
        return self.offset + self.parent.baseOffset;
    TMScope *previousSibling = [self.parent.children objectAtIndex:childIndex - 1];
    return self.offset + previousSibling.baseOffset + previousSibling.length;
}

+ (NSSet *)keyPathsForValuesAffectingBaseOffset
{
    return [NSSet setWithObjects:@"offset", @"parent.baseOffset", @"parent.children", nil];
}

- (NSArray *)children
{
    if (![_children count])
        return nil;
    return [_children copy];
}

- (id)initWithIdentifier:(NSString *)identifier string:(NSString *)string
{
    ECASSERT(identifier && string);
    self = [super init];
    if (!self)
        return nil;
    _identifier = identifier;
    _baseString = string;
    return self;
}

- (TMScope *)newChildScopeWithIdentifier:(NSString *)identifier
{
    ECASSERT(identifier);
    TMScope *childScope = [[[self class] alloc] init];
    childScope.parent = self;
    childScope.identifier = identifier;
    if (!_children)
        _children = [NSMutableArray array];
    [_children addObject:childScope];
    return childScope;
}

@end
