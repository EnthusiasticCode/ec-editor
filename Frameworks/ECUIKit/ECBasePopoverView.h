//
//  ECBasePopoverView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 09/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    ECPopoverViewArrowMetaPositionFarLeft = -1,
    ECPopoverViewArrowMetaPositionFarBottom = -1,
    ECPopoverViewArrowMetaPositionMiddle = 0,
    ECPopoverViewArrowMetaPositionFarRight = 1,
    ECPopoverViewArrowMetaPositionFarTop = 1
};
typedef NSInteger ECPopoverViewArrowMetaPosition;


@interface ECBasePopoverView : UIView

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
- (CGSize)arrowSizeForMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition;

/// Set the size of the arrow for the given meta position.
- (void)setArrowSize:(CGSize)arrowSize forMetaPosition:(ECPopoverViewArrowMetaPosition)metaPosition UI_APPEARANCE_SELECTOR;

/// The actual position of the arrow adjusted according to it's direction and view frame.
- (CGFloat)arrowActualPosition;

/// Returns the meta position of the arrow relative to the current frame.
- (ECPopoverViewArrowMetaPosition)currentArrowMetaPosition;

/// Gets the rotation transformation applied to the arrow for the given direction and meta position.
/// This method returns CGAffineTransformIdentity in it's default implementation.
- (CGAffineTransform)arrowRotationTransformInDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition;

#pragma mark Positioning

/// Insets used by a popover controller to modify the position of the popover when presented.
/// By default, the popover will be offsetted by the arrow's relevant size on a particular position. This insets can modify that offset.
@property (nonatomic) UIEdgeInsets positioningInsets;

@end
