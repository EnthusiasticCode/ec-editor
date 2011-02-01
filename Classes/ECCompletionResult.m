//
//  ECCompletionResult.m
//  edit
//
//  Created by Uri Baghin on 1/30/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCompletionResult.h"


@implementation ECCompletionResult

@synthesize cursorKind = _cursorKind;
@synthesize completionString = _completionString;

- (void)dealloc
{
    [_completionString release];
    [super dealloc];
}

- (id)initWithCursorKind:(int)cursorKind completionString:(ECCompletionString *)completionString
{
    self = [super init];
    if (self)
    {
        _cursorKind = cursorKind;
        _completionString = [completionString retain];
    }
    return self;
}

- (id)initWithCompletionString:(ECCompletionString *)completionString
{
    return [self initWithCursorKind:0 completionString:completionString];
}

+ (id)resultWithCursorKind:(int)cursorKind completionString:(ECCompletionString *)completionString
{
    id *result = [self alloc];
    result = [result initWithCursorKind:cursorKind completionString:completionString];
    return [result autorelease];
}

+ (id)resultWithCompletionString:(ECCompletionString *)completionString
{
    return [self resultWithCursorKind:0 completionString:completionString];
}

@end
