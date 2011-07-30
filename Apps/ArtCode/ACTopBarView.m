//
//  ACTopBarView.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACTopBarView.h"

@implementation ACTopBarView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (![self pointInside:point withEvent:event])
        return nil;
    
    // Effectively increase hit test area for subviews that are all layed out
    // on the x direction.
    CGRect bounds = self.bounds;
    point.y = bounds.origin.y + bounds.size.height / 2;
    return [super hitTest:point withEvent:event];
}

@end
