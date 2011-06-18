//
//  ACThemeView.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACThemeView.h"

@implementation ACThemeView

@synthesize backgroundInternalColor, borderColor, borderInsets, cornerRadius;

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        // TODO contentMode redraw instead?
        self.contentStretch = CGRectMake(0.5, 0.5, 0, 0);
        cornerRadius = 3;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    UIBezierPath *border = [UIBezierPath bezierPathWithRoundedRect:UIEdgeInsetsInsetRect(rect, borderInsets) cornerRadius:cornerRadius];
    
    if (backgroundInternalColor)
    {
        [backgroundInternalColor setFill];
        [border fill];
    }
    
    [borderColor setStroke];
    [border stroke];
}

@end
