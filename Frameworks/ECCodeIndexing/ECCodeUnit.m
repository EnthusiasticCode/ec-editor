//
//  ECCodeUnit.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeUnit.h"

@implementation ECCodeUnit

@dynamic index;
@dynamic fileURL;
@dynamic language;

- (NSArray *)completionsAtOffset:(NSUInteger)offset
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

- (NSArray *)tokensInRange:(NSRange)range withCursors:(BOOL)attachCursors
{
    return nil;
}

- (NSArray *)tokensWithCursors:(BOOL)attachCursors
{
    return nil;
}

- (ECCodeCursor *)cursor
{
    return nil;
}

- (ECCodeCursor *)cursorForOffset:(NSUInteger)offset
{
    return nil;
}

@end
