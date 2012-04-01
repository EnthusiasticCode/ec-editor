//
//  SplittableAccessoryView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
  KeyboardAccessoryPositionPortrait,
  KeyboardAccessoryPositionLandscape,
  KeyboardAccessoryPositionFloating
};
typedef NSInteger KeyboardAccessoryPosition;


@interface KeyboardAccessoryView : UIView

/// Returns the current accessory configuration.
- (KeyboardAccessoryPosition)currentAccessoryPosition;

/// Indicate if the accessory view should be splitted.
@property (nonatomic, getter = isSplit) BOOL split;

/// If splitted, the accessory view can be flipped vertically to be displayed on the bottom of the keyboard.
@property (nonatomic, getter = isFlipped) BOOL flipped;

/// View used as background when the accessory view is on a docked keyboard.
@property (nonatomic, strong) UIView *dockedBackgroundView;

/// View used as background of the left part of a floating keyboard.
@property (nonatomic, strong) UIView *splitLeftBackgroundView;

/// View used as background of the right part of a floating keyboard.
@property (nonatomic, strong) UIView *splitRightBackgroundView;

/// Inset to apply to the split background views.
@property (nonatomic) UIEdgeInsets splitBackgroundViewInsets;

@end
