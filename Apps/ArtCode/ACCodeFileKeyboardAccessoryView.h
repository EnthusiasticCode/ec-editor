//
//  ACCodeFileInputAccessoryView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    ACCodeFileKeyboardAccessoryPositionPortrait,
    ACCodeFileKeyboardAccessoryPositionLandscape,
    ACCodeFileKeyboardAccessoryPositionFloating
};
typedef NSInteger ACCodeFileKeyboardAccessoryPosition;


@interface ACCodeFileKeyboardAccessoryView : UIView

#pragma mark - Accessory Items

/// Array of UIBarButtonItem presented on the accessory view from left to right.
@property (nonatomic, strong) NSArray *items;
- (void)setItems:(NSArray *)items animated:(BOOL)animated;

/// Insets applyed to the content view.
- (void)setContentInsets:(UIEdgeInsets)insets forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;
- (UIEdgeInsets)contentInsetsForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;

/// Insets applyed to every item.
- (void)setItemInsets:(UIEdgeInsets)insets forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;
- (UIEdgeInsets)itemInsetsForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;

/// Width used for item of given position. If an item declare a width greater than 0, that with will be used instead.
- (void)setItemDefaultWidth:(CGFloat)width forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;
- (CGFloat)itemDefaultWidthForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;

/// Set the image used for button items.
@property (nonatomic, strong) UIImage *itemBackgroundImage;

/// Returns the current accessory configuration.
- (ACCodeFileKeyboardAccessoryPosition)currentAccessoryPosition;

#pragma mark - Managing Accessory Appearance

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


@interface ACCodeFileKeyboardAccessoryItem : UIBarButtonItem

- (void)setWidth:(CGFloat)width forAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;
- (CGFloat)widthForAccessoryPosition:(ACCodeFileKeyboardAccessoryPosition)position;

@end
