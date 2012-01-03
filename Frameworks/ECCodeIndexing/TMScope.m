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
    return [self.baseString substringWithRange:NSMakeRange(self.baseOffset, self.length)];
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
    return self.offset + self.parent.baseOffset;
}

- (void)setBaseOffset:(NSUInteger)baseOffset
{
    ECASSERT(baseOffset >= self.parent.baseOffset);
    self.offset = baseOffset - self.parent.baseOffset;
}

+ (NSSet *)keyPathsForValuesAffectingBaseOffset
{
    return [NSSet setWithObjects:@"offset", @"parent.baseOffset", nil];
}

- (NSArray *)children
{
    return [_children copy];
}

- (NSUInteger)countOfChildren
{
    return [_children count];
}

- (NSArray *)childrenAtIndexes:(NSIndexSet *)indexes
{
    return [_children objectsAtIndexes:indexes];
}

- (void)getChildren:(TMScope * __unsafe_unretained *)buffer range:(NSRange)inRange
{
    return [_children getObjects:buffer range:inRange];
}

- (void)insertChildren:(NSArray *)array atIndexes:(NSIndexSet *)indexes
{
    [_children insertObjects:array atIndexes:indexes];
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)indexes
{
    [_children removeObjectsAtIndexes:indexes];
}

- (void)replaceChildrenAtIndexes:(NSIndexSet *)indexes withChildren:(NSArray *)array
{
    [_children replaceObjectsAtIndexes:indexes withObjects:array];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    _children = [NSMutableArray array];
    return self;
}

- (id)initWithIdentifier:(NSString *)identifier string:(NSString *)string
{
    ECASSERT(identifier && string);
    self = [self init];
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
    [[self mutableArrayValueForKey:@"children"] addObject:childScope];
    return childScope;
}

@end
