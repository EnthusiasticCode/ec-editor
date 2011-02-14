//
//  ECFixIt.m
//  edit
//
//  Created by Uri Baghin on 2/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECFixIt.h"


@implementation ECFixIt

@synthesize string = _string;
@synthesize replacementRange = _replacementRange;

- (void)dealloc
{
    [_string release];
    [_replacementRange release];
    [super dealloc];
}

- (id)initWithString:(NSString *)string replacementRange:(ECSourceRange *)replacementRange
{
    self = [super init];
    if (self)
    {
        _string = [string copy];
        _replacementRange = [replacementRange retain];
    }
    return self;
}

+ (id)fixItWithString:(NSString *)string replacementRange:(ECSourceRange *)replacementRange
{
    id fixIt = [self alloc];
    fixIt = [fixIt initWithString:string replacementRange:replacementRange];
    return [fixIt autorelease];
}

@end
