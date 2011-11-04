//
//  ECPopoverView.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ECPopoverView : UIView

#pragma mark Style

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;

/// Specify a shadow offset to apply as the layer shadow offset that will be
/// automaticaly oriented based on the arrow direction.
@property (nonatomic) CGSize shadowOffsetForArrowDirectionUpToAutoOrient UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat shadowOpacity UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat shadowRadius UI_APPEARANCE_SELECTOR;

#pragma mark Content

@property (nonatomic, strong) UIView *contentView;

/// The content size. Chaning this property will affect the receiver's bounds.
@property (nonatomic) CGSize contentSize;

@property (nonatomic) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

@property (nonatomic, readonly, strong) UIView *contentWrapView;

@property (nonatomic) CGFloat contentWrapCornerRadius UI_APPEARANCE_SELECTOR;

#pragma mark Top Bar

@property (nonatomic, strong) UIView *barView;

#pragma mark Arrow

@property (nonatomic) UIPopoverArrowDirection arrowDirection;

@property (nonatomic) CGFloat arrowPosition;

@property (nonatomic) CGFloat arrowSize UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat arrowCornerRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat arrowMargin;

@end
