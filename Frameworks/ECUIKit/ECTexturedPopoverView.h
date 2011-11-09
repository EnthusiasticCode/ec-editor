//
//  ECTexturedPopoverView.h
//  ECUIKit
//
//  Created by Nicola Peduzzi on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECBasePopoverView.h"

@interface ECTexturedPopoverView : ECBasePopoverView

#pragma mark Arrow Styling

/// The arrow view
@property (nonatomic, readonly, strong) UIImageView *arrowView;

/// Gets the image used for the arrow in the given direction and meta position.
/// If the image for the given meta position does not exist, the image for the middle meta position
/// of the same direction will be returned instead.
- (UIImage *)arrowImageForDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition;

/// Set an image to use as arrow on the given direction and meta position.
/// The meta position is used to specify a different image for arrows positioned in the middle or on the far angles.
- (void)setArrowImage:(UIImage *)image forDirection:(UIPopoverArrowDirection)direction metaPosition:(ECPopoverViewArrowMetaPosition)metaPosition UI_APPEARANCE_SELECTOR;

#pragma mark - View Styling

- (id)initWithBackgroundImage:(UIImage *)image;

/// The view to use as the background.
@property (nonatomic, readonly, strong) UIImageView *backgroundView;

@end
