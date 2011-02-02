//
//  ECSourceLocation.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECSourceLocation.h"


@implementation ECSourceLocation

@synthesize file = _file;
@synthesize line = _line;
@synthesize column = _column;
@synthesize offset = _offset;

- (void)dealloc
{
    [_file release];
    [super dealloc];
}

- (id)initWithFile:(NSString *)file line:(unsigned int)line column:(unsigned int)column offset:(unsigned int)offset
{
    self = [super init];
    if (self)
    {
        _file = [file retain];
        _line = line;
        _column = column;
        _offset = offset;
    }
    return self;
}

+ (id)locationWithFile:(NSString *)file line:(unsigned int)line column:(unsigned int)column offset:(unsigned int)offset
{
    id location = [self alloc];
    location = [location initWithFile:file line:line column:column offset:offset];
    return [location autorelease];
}

@end
