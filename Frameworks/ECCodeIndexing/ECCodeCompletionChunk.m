//
//  ECCodeCompletionChunk.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionChunk.h"
#import <ECFoundation/ECHashing.h>
#import "ECCodeIndexing+PrivateInitializers.h"

@interface ECCodeCompletionChunk ()
{
    NSUInteger _hash;
}
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionChunk

@synthesize kind = _kind;
@synthesize string = _string;


- (id)initWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string
{
    self = [super init];
    if (self)
    {
        _kind = kind;
        _string = [string copy];
        _hash = [self computeHash];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSUInteger)hash
{
    return _hash;
}

- (NSUInteger)computeHash
{
    const NSUInteger propertyCount = 2;
    NSUInteger propertyHashes[2] = { _kind, [_string hash] };
    return ECHashNSUIntegers(propertyHashes, propertyCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeCompletionChunk *otherChunk = other;
    if (!otherChunk.kind == _kind)
        return NO;
    if (_string || otherChunk.string)
        if (![otherChunk.string isEqual:_string])
            return NO;
    return YES;
}

@end
