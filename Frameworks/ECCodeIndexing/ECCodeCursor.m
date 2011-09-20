//
//  ECCodeCursor.m
//  ECCodeIndexing
//
//  Created by Uri Baghin on 3/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeCursor.h"
#import "ECCodeUnit.h"
#import <ECFoundation/ECHashing.h>

@implementation ECCodeCursor

@dynamic language;
@dynamic kind;
@dynamic spelling;
@dynamic file;
@dynamic offset;
@dynamic extent;
@dynamic unifiedSymbolResolution;
@dynamic parent;

- (NSOrderedSet *)childCursors
{
    return nil;
}

- (void)enumerateChildCursorsWithBlock:(ECCodeChildVisitResult (^)(ECCodeCursor *, ECCodeCursor *))enumerationBlock
{
    
}

@end
