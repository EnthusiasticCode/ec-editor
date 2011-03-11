//
//  ECCodeCompletionString.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"
#import <ECFoundation/ECHashing.h>

@interface ECCodeCompletionString ()
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionString

@synthesize completionChunks = _completionChunks;

- (void)dealloc
{
    [_completionChunks release];
    [super dealloc];
}

- (id)initWithCompletionChunks:(NSArray *)completionChunks
{
    self = [super init];
    if (self)
    {
        _completionChunks = [completionChunks copy];
        _hash = [self computeHash];
    }
    return self;
}

+ (id)stringWithCompletionChunks:(NSArray *)completionChunks
{
    id string = [self alloc];
    string = [string initWithCompletionChunks:completionChunks];
    return [string autorelease];
}

- (ECCodeCompletionChunk *)firstChunk
{
    if (_completionChunks && [_completionChunks count])
        return [_completionChunks objectAtIndex:0];
    return nil;
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
    NSUInteger chunkCount = [_completionChunks count];
    NSUInteger *chunkHashes =  malloc(chunkCount * sizeof(NSUInteger));
    for (NSUInteger i = 0; i < chunkCount; i++)
    {
        chunkHashes[i] = [[_completionChunks objectAtIndex:i] hash];
    }
    return ECHashNSUIntegers(chunkHashes, chunkCount);
}

- (BOOL)isEqual:(id)other
{
    if ([super isEqual:other])
        return YES;
    if (![other isKindOfClass:[self class]])
        return NO;
    ECCodeCompletionString *otherString = other;
    if (otherString.completionChunks || _completionChunks)
        if (![otherString.completionChunks isEqual:_completionChunks])
            return NO;
    return YES;
}

@end
