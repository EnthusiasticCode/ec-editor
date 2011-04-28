//
//  Group.m
//  edit
//
//  Created by Uri Baghin on 4/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Group.h"
#import "File.h"
#import "Folder.h"

@implementation Group
@dynamic index;
@dynamic items;
@dynamic area;

- (void)addItemsObject:(File *)value
{
    [self addObject:value forOrderedKey:@"items"];
}

- (void)removeItemsObject:(File *)value
{
    [self removeObject:value forOrderedKey:@"items"];
}

- (void)addItems:(NSSet *)value
{
    [self addObjects:value forOrderedKey:@"items"];
}

- (void)removeItems:(NSSet *)value
{
    [self removeObjects:value forOrderedKey:@"items"];
}

- (NSArray *)orderedItems
{
    return [self valueForOrderedKey:@"items"];
}

@end
