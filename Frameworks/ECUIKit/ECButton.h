//
//  ECMockupButton.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECButton : UIButton

@property (nonatomic) CGFloat borderWidth;

@property (nonatomic) CGFloat cornerRadius;

@property (nonatomic) CGFloat leftArrowSize;
@property (nonatomic) CGFloat rightArrowSize;

- (void)setBackgroundColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)backgroundColorForState:(UIControlState)state;

- (void)setBorderColor:(UIColor *)color forState:(UIControlState)state;
- (UIColor *)borderColorForState:(UIControlState)state;

@end
