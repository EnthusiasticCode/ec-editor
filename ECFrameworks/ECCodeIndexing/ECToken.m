//
//  ECToken.m
//  edit
//
//  Created by Uri Baghin on 2/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECToken.h"


@implementation ECToken

@synthesize kind = _kind;
@synthesize spelling = _spelling;
@synthesize location = _location;
@synthesize extent = _extent;

- (void)dealloc
{
    [_spelling release];
    [_location release];
    [_extent release];
    [super dealloc];
}

- (id)initWithKind:(ECTokenKind)kind spelling:(NSString *)spelling location:(ECSourceLocation *)location extent:(ECSourceRange *)extent
{
    self = [super init];
    if (self)
    {
        _kind = kind;
        _spelling = [spelling copy];
        _location = [location retain];
        _extent = [extent retain];
    }
    return self;
}

+ (id)tokenWithKind:(ECTokenKind)kind spelling:(NSString *)spelling location:(ECSourceLocation *)location extent:(ECSourceRange *)extent
{
    id token = [self alloc];
    token = [token initWithKind:kind spelling:spelling location:location extent:extent];
    return [token autorelease];
}

- (NSString *)description
{
    return self.spelling;
}

@end
