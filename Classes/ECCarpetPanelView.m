//
//  ECCarpetPanelView.m
//  edit
//
//  Created by Nicola Peduzzi on 17/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCarpetPanelView.h"


@implementation ECCarpetPanelView

@synthesize panelSize;
@synthesize panelPosition;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    {
        self.autoresizingMask = 
            UIViewAutoresizingFlexibleWidth
            | UIViewAutoresizingFlexibleHeight
            | UIViewAutoresizingFlexibleLeftMargin
            | UIViewAutoresizingFlexibleRightMargin
            | UIViewAutoresizingFlexibleTopMargin
            | UIViewAutoresizingFlexibleBottomMargin;
    }
    return self;
}

- (CGFloat)panelSizeInUnits
{
    if (panelSize <= 0)
        return 0;
    // Defined absolute panelSize
    if (panelSize > 1)
        return panelSize;
    // Percentual panelSize
    CGFloat superSize;
    int direction = (NSInteger)[[self superview] direction];
    if (direction == 0)
        superSize = [self superview].bounds.size.width;
    else
        superSize = [self superview].bounds.size.height;
    return superSize * panelSize;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void)removeFromSuperview
{
    // Disabled to avoid manual removal of this view.
    // FIX how do I remove it tho?
}

- (void)dealloc 
{
    [super dealloc];
}


@end
