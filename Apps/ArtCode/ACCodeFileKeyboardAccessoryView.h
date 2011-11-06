//
//  ACCodeFileInputAccessoryView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 06/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    ACCodeFileKeyboardAccessoryItemSizeNormal,
    ACCodeFileKeyboardAccessoryItemSizeBig,
    ACCodeFileKeyboardAccessoryItemSizeSmall,
    ACCodeFileKeyboardAccessoryItemSizeSmallImportant
};
typedef NSInteger ACCodeFileKeyboardAccessoryItemSize;


@interface ACCodeFileKeyboardAccessoryView : UIView

#pragma mark - Accessory Buttons

/// Array of UIBarButtonItem presented on the accessory view from left to right.
@property (nonatomic, strong) NSArray *items;
- (void)setItems:(NSArray *)items animated:(BOOL)animated;

/// Insets applyed view bounds to fit items.
- (void)setItemsInsets:(UIEdgeInsets)insets forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;
- (UIEdgeInsets)itemsInsetsForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;

/// Set the image used for button items of the given size.
- (void)setButtonItemBackgroundImage:(UIImage *)image forItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;
- (UIImage *)buttonItemBackgroundImageForItemSize:(ACCodeFileKeyboardAccessoryItemSize)size;

/// Returns the size of the items with the current accessory configuration.
- (ACCodeFileKeyboardAccessoryItemSize)currentItemSize;

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
