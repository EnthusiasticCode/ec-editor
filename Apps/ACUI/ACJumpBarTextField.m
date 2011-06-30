//
//  ACJumpBarTextField.m
//  ACUI
//
//  Created by Nicola Peduzzi on 30/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACJumpBarTextField.h"

@implementation ACJumpBarTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    bounds = [super textRectForBounds:bounds];
    bounds.origin.x += 3;
    bounds.size.width -= 3;
    return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

@end
