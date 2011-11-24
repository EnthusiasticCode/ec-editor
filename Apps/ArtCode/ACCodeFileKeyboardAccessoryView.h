//
//  ACCodeFileKeyboardAccessoryView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECKeyboardAccessoryView.h>
#import "ACCodeFileKeyboardAccessoryPopoverView.h"

@interface ACCodeFileKeyboardAccessoryView : ECKeyboardAccessoryView

/// Array of UIBarButtonItem presented on the accessory view from left to right.
@property (nonatomic, copy) NSArray *items;

/// Set the image used for button items.
@property (nonatomic, strong) UIImage *itemBackgroundImage;

/// Insets applyed to the content view.
- (void)setContentInsets:(UIEdgeInsets)insets forAccessoryPosition:(ECKeyboardAccessoryPosition)position;
- (UIEdgeInsets)contentInsetsForAccessoryPosition:(ECKeyboardAccessoryPosition)position;

/// Insets applyed to every item.
- (void)setItemInsets:(UIEdgeInsets)insets forAccessoryPosition:(ECKeyboardAccessoryPosition)position;
- (UIEdgeInsets)itemInsetsForAccessoryPosition:(ECKeyboardAccessoryPosition)position;

/// Width used for item of given position. If an item declare a width greater than 0, that with will be used instead.
- (void)setItemDefaultWidth:(CGFloat)width forAccessoryPosition:(ECKeyboardAccessoryPosition)position;
- (CGFloat)itemDefaultWidthForAccessoryPosition:(ECKeyboardAccessoryPosition)position;

#pragma mark - Managing popover view for items

/// The popover view. The view will be displayed as touching the item with the 
/// arrow directly under it.
@property (nonatomic, readonly, strong) ACCodeFileKeyboardAccessoryPopoverView *itemPopoverView;
- (void)presentPopoverForItemAtIndex:(NSUInteger)index permittedArrowDirection:(UIPopoverArrowDirection)direction animated:(BOOL)animated;
- (void)dismissPopoverForItemAnimated:(BOOL)animated;
@property (nonatomic, copy) void (^willPresentPopoverForItemBlock)(ACCodeFileKeyboardAccessoryView *sender, NSUInteger itemIndex, CGRect popoverContentRect, NSTimeInterval animationDuration);
@property (nonatomic, copy) void (^willDismissPopoverForItemBlock)(ACCodeFileKeyboardAccessoryView *sender, NSTimeInterval animationDuration);

@end


@interface ACCodeFileKeyboardAccessoryItem : UIBarButtonItem

- (void)setWidth:(CGFloat)width forAccessoryPosition:(ECKeyboardAccessoryPosition)position;
- (CGFloat)widthForAccessoryPosition:(ECKeyboardAccessoryPosition)position;

@end