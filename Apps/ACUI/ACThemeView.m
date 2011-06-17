//
//  ACThemeView.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACThemeView.h"

@implementation ACThemeView

@synthesize borderColor, borderInsets;

- (void)drawRect:(CGRect)rect
{
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    [borderColor setStroke];
    [[UIBezierPath bezierPathWithRoundedRect:UIEdgeInsetsInsetRect(rect, borderInsets) cornerRadius:5] stroke];
}

@end
