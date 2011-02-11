//
//  ECCompletionChunk.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCompletionChunk.h"


@implementation ECCompletionChunk

@synthesize kind = _kind;
@synthesize string = _string;

- (void)dealloc
{
    [_string release];
    [super dealloc];
}

- (id)initWithKind:(ECCompletionChunkKind)kind string:(NSString *)string
{
    self = [super init];
    if (self)
    {
        _kind = kind;
        _string = [string retain];
    }
    return self;
}

- (id)initWithString:(NSString *)string
{
    return [self initWithKind:ECCompletionChunkKindTypedText string:string];
}

+ (id)chunkWithKind:(ECCompletionChunkKind)kind string:(NSString *)string
{
    id chunk = [self alloc];
    chunk = [chunk initWithKind:kind string:string];
    return [chunk autorelease];
}

+ (id)chunkWithString:(NSString *)string
{
    return [self chunkWithKind:ECCompletionChunkKindTypedText string:string];
}

@end
