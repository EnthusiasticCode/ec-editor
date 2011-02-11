//
//  ECSourceRange.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSourceRange.h"
#import "ECSourceLocation.h"

@implementation ECSourceRange

@synthesize start = _start;
@synthesize end = _end;

- (void)dealloc
{
    [_start release];
    [_end release];
    [super dealloc];
}

- (id)initWithStart:(ECSourceLocation *)start end:(ECSourceLocation *)end
{
    self = [super init];
    if (self)
    {
        _start = [start retain];
        _end = [end retain];
    }
    return self;
}

+ (id)rangeWithStart:(ECSourceLocation *)start end:(ECSourceLocation *)end
{
    id range = [self alloc];
    range = [range initWithStart:start end:end];
    return [range autorelease];
}

@end
