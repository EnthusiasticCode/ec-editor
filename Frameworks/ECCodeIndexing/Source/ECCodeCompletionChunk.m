//
//  ECCodeCompletionChunk.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionChunk.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeCompletionChunk ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionChunk

@synthesize kind = _kind;
@synthesize string = _string;

- (void)dealloc
{
    [_string release];
    [super dealloc];
}

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

- (id)initWithString:(NSString *)string
{
    return [self initWithKind:ECCodeCompletionChunkKindTypedText string:string];
}

+ (id)chunkWithKind:(ECCodeCompletionChunkKind)kind string:(NSString *)string
{
    id chunk = [self alloc];
    chunk = [chunk initWithKind:kind string:string];
    return [chunk autorelease];
}

+ (id)chunkWithString:(NSString *)string
{
    return [self chunkWithKind:ECCodeCompletionChunkKindTypedText string:string];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
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
