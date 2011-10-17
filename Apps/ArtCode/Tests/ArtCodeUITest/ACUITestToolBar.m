//
//  ACUITestToolBar.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACUITestToolBar.h"

@interface ACUITestToolbar ()

@property (nonatomic, strong) UIButton *titleItem;

@end

@implementation ACUITestToolbar

@synthesize titleItem = _titleItem;
@synthesize toolItem = _toolItem;

- (void)setToolItem:(UIBarButtonItem *)toolItem
{
    [self setToolItem:toolItem animated:NO];
}

- (void)setToolItem:(UIBarButtonItem *)toolItem animated:(BOOL)animated
{
    if (toolItem == _toolItem)
        return;
    
    [self willChangeValueForKey:@"toolItem"];
    
    NSMutableArray *newItems = [self.items mutableCopy];
    NSUInteger count = [newItems count];
    if (_toolItem)
        [newItems removeObject:_toolItem];
    if (toolItem)
        [newItems insertObject:toolItem atIndex:count - 2];
    
    _toolItem = toolItem;
    [self setItems:newItems animated:animated];
    
    [self didChangeValueForKey:@"toolItem"];
}

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    ECASSERT([items count] >= 5 && "This kind of bar must have 4 buttons and a title item");
    
    for (UIBarItem *item in items)
    {
        if ([item isKindOfClass:[UIBarButtonItem class]])
        {
            UIBarButtonItem *buttonItem = (UIBarButtonItem *)item;
            if (buttonItem.customView != nil && [buttonItem.customView isKindOfClass:[UIButton class]])
            {
                self.titleItem = (UIButton *)buttonItem.customView;
            }
        }
    }
    
    [self willChangeValueForKey:@"toolItem"];
    _toolItem = [items objectAtIndex:[items count] - 2];
    [self didChangeValueForKey:@"toolItem"];
    
    [super setItems:items animated:animated];
}

@end
