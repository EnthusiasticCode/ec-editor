//
//  ECCodeCompletionString.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCompletionString.h"
#import "ECCodeCompletionChunk.h"
#import "ECHashing.h"

@interface ECCodeCompletionString ()
{
    NSUInteger _hash;
}
- (NSUInteger)computeHash;
@end

@implementation ECCodeCompletionString

@synthesize completionChunks = _completionChunks;


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
    return string;
}

- (NSString *)typedText
{
    for (ECCodeCompletionChunk *chunk in _completionChunks)
        if (chunk.kind == ECCodeCompletionChunkKindTypedText)
            return chunk.string;
    [NSException raise:NSInternalInconsistencyException format:@"ECCodeCompletionString without a TypedText chunk."];
    return nil;
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
    NSUInteger chunkCount = [_completionChunks count];
    NSUInteger *chunkHashes =  malloc(chunkCount * sizeof(NSUInteger));
    for (NSUInteger i = 0; i < chunkCount; ++i)
        chunkHashes[i] = [[_completionChunks objectAtIndex:i] hash];
    NSUInteger hash = ECHashNSUIntegers(chunkHashes, chunkCount);
    free(chunkHashes);
    return hash;
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
