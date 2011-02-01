//
//  ECCompletionString.m
//  edit
//
//  Created by Uri Baghin on 1/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCompletionString.h"
#import "ECCompletionChunk.h"

@implementation ECCompletionString

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
        _completionChunks = [completionChunks retain];
    return self;
}

+ (id)stringWithCompletionChunks:(NSArray *)completionChunks
{
    id string = [self alloc];
    string = [string initWithCompletionChunks:completionChunks];
    return [string autorelease];
}

- (ECCompletionChunk *)firstChunkWithKind:(int)kind
{
    for (ECCompletionChunk *chunk in self.completionChunks)
    {
        if (chunk.kind == kind)
            return chunk;
    }
    return nil;
}

- (ECCompletionChunk *)firstChunk
{
    if (self.completionChunks && [self.completionChunks count])
        return [self.completionChunks objectAtIndex:0];
    return nil;
}

@end
