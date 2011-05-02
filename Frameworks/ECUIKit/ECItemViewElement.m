//
//  ECItemViewElement.m
//  edit
//
//  Created by Uri Baghin on 5/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECItemViewElement.h"

@implementation ECItemViewElement

@synthesize editing = _isEditing;
@synthesize selected = _isSelected;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    self.editing = editing;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    self.selected = selected;
}

@end
