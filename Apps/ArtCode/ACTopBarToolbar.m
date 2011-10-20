//
//  ACTopBarToolbar.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarToolbar.h"
#import "ACTopBarTitleControl.h"


@interface ACTopBarToolbar ()

@property (nonatomic, strong) UIButton *titleControl;

@end


@implementation ACTopBarToolbar

@synthesize titleControl = _titleControl;
@synthesize editItem = _editItem, toolItems = _toolItems;

- (void)setEditItem:(UIBarButtonItem *)editItem
{
    if (editItem == _editItem)
        return;
    
    [self willChangeValueForKey:@"editItem"];
    
    NSMutableArray *newItems = [self.items mutableCopy];
    if (_editItem)
        [newItems removeObject:_editItem];
    if (editItem)
        [newItems addObject:editItem];
    
    _editItem = editItem;
    [super setItems:newItems animated:NO];
    
    [self didChangeValueForKey:@"editItem"];
}

- (void)setToolItems:(NSArray *)toolItems
{
    [self setToolItems:toolItems animated:NO];
}

- (void)setToolItems:(NSArray *)toolItems animated:(BOOL)animated
{
    if (toolItems == _toolItems)
        return;
    
    [self willChangeValueForKey:@"toolItems"];
    
    NSMutableArray *newItems = [self.items mutableCopy];
    NSUInteger count = [newItems count];
    if (_toolItems)
        [newItems removeObjectsInArray:_toolItems];
    if (toolItems)
        [newItems insertObjects:toolItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count - 2, [toolItems count])]];
    
    _toolItems = toolItems;
    [super setItems:newItems animated:animated];
    
    [self didChangeValueForKey:@"toolItems"];
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    ECASSERT([items count] >= 5 && "This kind of bar must have 4 buttons and a title item");
    
    for (UIBarItem *item in items)
    {
        if ([item isKindOfClass:[UIBarButtonItem class]])
        {
            UIBarButtonItem *buttonItem = (UIBarButtonItem *)item;
            if (buttonItem.customView != nil && [buttonItem.customView isKindOfClass:[ACTopBarTitleControl class]])
            {
                self.titleControl = (ACTopBarTitleControl *)buttonItem.customView;
            }
        }
    }
    
    [self willChangeValueForKey:@"toolItems"];
    _toolItems = [NSArray arrayWithObject:[items objectAtIndex:[items count] - 2]];
    [self didChangeValueForKey:@"toolItems"];
    
    [self willChangeValueForKey:@"editItem"];
    _editItem = [items objectAtIndex:[items count] - 1];
    [self didChangeValueForKey:@"editItem"];
    
    [super setItems:items animated:animated];
}

@end
