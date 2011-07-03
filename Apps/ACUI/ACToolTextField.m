//
//  ACToolTextField.m
//  ACUI
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACToolTextField.h"

@implementation ACToolTextField

- (CGRect)textRectForBounds:(CGRect)bounds
{
    bounds = [super textRectForBounds:bounds];
    bounds.origin.x += 11;
    bounds.size.width -= 11;
    return bounds;
}

- (CGRect)editingRectForBounds:(CGRect)bounds
{
    return [self textRectForBounds:bounds];
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds
{
    bounds = [super rightViewRectForBounds:bounds];
    bounds.origin.x -= 11;
    return bounds;
}

@end
