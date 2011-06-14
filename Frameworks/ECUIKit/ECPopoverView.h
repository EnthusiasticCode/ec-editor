//
//  ECPopoverView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ECPopoverView : UIView <UIAppearanceContainer>

#pragma mark Style

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;

#pragma mark Content

@property (nonatomic) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGSize contentSize;

@property (nonatomic, strong) UIView *contentView;

#pragma mark Arrow

@property (nonatomic) UIPopoverArrowDirection arrowDirection;

@property (nonatomic) CGFloat arrowPosition;

@property (nonatomic) CGFloat arrowSize;

@property (nonatomic) CGFloat arrowCornerRadius;

@property (nonatomic, readonly) CGFloat arrowMargin;

@end
