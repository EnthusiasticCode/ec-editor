//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"

@implementation ECCodeCursor

@dynamic language;
@dynamic kind;
@dynamic kindCategory;
@dynamic spelling;
@dynamic fileURL;
@dynamic offset;
@dynamic extent;
@dynamic unifiedSymbolResolution;
@dynamic parent;

- (NSArray *)childCursors
{
    return nil;
}

- (void)enumerateChildCursorsWithBlock:(ECCodeChildVisitResult (^)(ECCodeCursor *, ECCodeCursor *))enumerationBlock
{
    
}

@end
