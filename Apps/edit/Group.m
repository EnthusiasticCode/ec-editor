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

static NSString *GroupObservingContext = @"GroupObservingContext";

@interface Group ()
- (void)_attachObservers;
@end

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

- (void)_attachObservers
{
    [self addObserver:self forKeyPath:@"items" options:NSKeyValueObservingOptionNew context:GroupObservingContext];
}

- (void)awakeFromFetch
{
    [super awakeFromFetch];
    [self _attachObservers];
}

- (void)awakeFromInsert
{
    [super awakeFromInsert];
    [self _attachObservers];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != GroupObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if ([[change valueForKey:NSKeyValueChangeKindKey] intValue] != NSKeyValueChangeInsertion)
        return;
    NSSet *insertedObjects = [change valueForKey:NSKeyValueChangeNewKey];
    if (![insertedObjects count])
        return;
    for (File *file in insertedObjects)
        if (file.folder != self.area)
            [[self.area mutableSetValueForKey:@"files"] addObject:file];
}

- (NSMutableArray *)orderedItems
{
    return [self mutableArrayValueForOrderedKey:@"items"];
}

@end
