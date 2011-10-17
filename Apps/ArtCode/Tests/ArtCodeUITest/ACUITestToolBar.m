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

- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
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
    
    [super setItems:items animated:animated];
}

@end
