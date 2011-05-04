//
//  ECItemViewElement.m
//  edit
//
//  Created by Uri Baghin on 5/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemViewElement.h"

@implementation ECItemViewElement

@synthesize type = _type;
@synthesize indexPath = _indexPath;
@synthesize editing = _isEditing;
@synthesize selected = _isSelected;
@synthesize dragged = _isDragged;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    self.editing = editing;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (!selected && animated)
        [UIView animateWithDuration:0.15 animations:^(void) {
            self.alpha = selected ? 0.5 : 1.0;
        }];
    else
        self.alpha = selected ? 0.5 : 1.0;
}

- (void)setDragged:(BOOL)dragged animated:(BOOL)animated
{
    self.dragged = dragged;
}

@end
