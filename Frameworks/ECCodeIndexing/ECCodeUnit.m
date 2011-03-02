//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@implementation ECCodeUnit

@synthesize index = _index;
@synthesize url = _url;
@synthesize language = _language;

- (NSArray *)completionsWithSelection:(NSRange)selection
{
    return nil;
}

- (NSArray *)diagnostics
{
    return nil;
}

- (NSArray *)fixIts
{
    return nil;
}

- (NSArray *)tokensInRange:(NSRange)range
{
    return nil;
}

- (NSArray *)tokens;
{
    return nil;
}

@end
