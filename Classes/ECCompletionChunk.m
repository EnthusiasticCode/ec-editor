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

- (id)initWithKind:(int)kind string:(NSString *)string
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
    return [self initWithKind:0 string:string];
}

+ (id)chunkWithKind:(int)kind string:(NSString *)string
{
    id chunk = [self alloc];
    chunk = [chunk initWithKind:kind string:string];
    return [chunk autorelease];
}

+ (id)chunkWithString:(NSString *)string
{
    return [self chunkWithKind:0 string:string];
}

@end
