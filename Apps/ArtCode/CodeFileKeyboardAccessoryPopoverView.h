//
//  CodeFileKeyboardAccessoryPopoverView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    PopoverViewArrowMetaPositionFarLeft = -1,
    PopoverViewArrowMetaPositionFarBottom = -1,
    PopoverViewArrowMetaPositionMiddle = 0,
    PopoverViewArrowMetaPositionFarRight = 1,
    PopoverViewArrowMetaPositionFarTop = 1
};
typedef NSInteger PopoverViewArrowMetaPosition;


@interface CodeFileKeyboardAccessoryPopoverView : UIView


#pragma mark Content

/// The content view to add to this popover
@property (nonatomic, strong) UIView *contentView;

/// The content size. Chaning this property will affect the receiver's bounds.
@property (nonatomic) CGSize contentSize;

/// Insets to apply to the content view.
@property (nonatomic) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

#pragma mark Arrow Layout

/// The direction of the arrow
@property (nonatomic) UIPopoverArrowDirection arrowDirection;

/// The arrow position specified in points.
@property (nonatomic) CGFloat arrowPosition;

/// Insets of the arrow. Only the margin opposite to the arrow direction will be considered.
/// For example, if the arrow is positioned on the up direction, the bottom margin will be used 
/// to compute its position relative to the view.
@property (nonatomic) UIEdgeInsets arrowInsets UI_APPEARANCE_SELECTOR;

/// Returns the size of the arrow in the given meta position as if it was in the up direction.
- (CGSize)arrowSizeForMetaPosition:(PopoverViewArrowMetaPosition)metaPosition;

/// Set the size of the arrow for the given meta position.
- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(PopoverViewArrowMetaPosition)metaPosition UI_APPEARANCE_SELECTOR;

/// The actual position of the arrow adjusted according to it's direction and view frame.
- (CGFloat)arrowActualPosition;

/// Returns the meta position of the arrow relative to the current frame.
- (PopoverViewArrowMetaPosition)currentArrowMetaPosition;

/// Gets the rotation transformation applied to the arrow for the given direction and meta position.
/// This method returns CGAffineTransformIdentity in it's default implementation.
- (CGAffineTransform)arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition;

#pragma mark Positioning

/// Insets used by a popover controller to modify the position of the popover when presented.
/// By default, the popover will be offsetted by the arrow's relevant size on a particular position. This insets can modify that offset.
@property (nonatomic) UIEdgeInsets positioningInsets;

#pragma mark Arrow Styling

/// The arrow view
@property (nonatomic, readonly, strong) UIImageView *arrowView;

/// Gets the image used for the arrow in the given direction and meta position.
/// If the image for the given meta position does not exist, the image for the middle meta position
/// of the same direction will be returned instead.
- (UIImage *)arrowImageForDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition;

/// Set an image to use as arrow on the given direction and meta position.
/// The meta position is used to specify a different image for arrows positioned in the middle or on the far angles.
- (void)setArrowImage:(UIImage *)image forDirection:(UIPopoverArrowDirection)direction metaPosition:(PopoverViewArrowMetaPosition)metaPosition UI_APPEARANCE_SELECTOR;

#pragma mark - View Styling

- (id)initWithBackgroundImage:(UIImage *)image;

/// The view to use as the background.
@property (nonatomic, readonly, strong) UIImageView *backgroundView;

@end
