//
//  ECMockupButton.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECButton : UIButton {
    NSMutableArray *backgroundColors;
    CGMutablePathRef buttonPath;
}

@property (nonatomic) UIEdgeInsets arrowSizes;

@property (nonatomic, retain) UIColor *borderColor;

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)backgroundColorForState:(UIControlState)state;

@end
