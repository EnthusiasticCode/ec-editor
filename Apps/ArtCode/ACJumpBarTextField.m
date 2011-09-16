//
//  ACJumpBarTextField.m
//  ACUI
//
//  Created by Nicola Peduzzi on 30/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACJumpBarTextField.h"
#import "AppStyle.h"

@implementation ACJumpBarTextField

//- (id)initWithFrame:(CGRect)frame
//{
//    if ((self = [super initWithFrame:frame]))
//    {
//        UIButton *rightButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 16, 17)];
//        [rightButton setImage:[UIImage styleSearchIconWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
//        [rightButton setImage:[UIImage styleCloseImageWithColor:[UIColor styleForegroundColor] outlineColor:nil] forState:UIControlStateSelected];
//        [rightButton setBackgroundImage:nil forState:UIControlStateNormal];
//        [rightButton setBackgroundImage:nil forState:UIControlStateHighlighted];
//        rightButton.adjustsImageWhenHighlighted = NO;
//        self.rightView = rightButton;
//        self.rightViewMode = UITextFieldViewModeAlways;
//    }
//    return self;
//}


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
