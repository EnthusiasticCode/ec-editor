//
//  ECRoundedContentCornersView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 16/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// This view will create 4 shape layers that will be layed out on the corners
/// of the view and kept in front of every other subview.
/// This will give the effect of rounded corners for the content.
@interface ECRoundedContentCornersView : UIView

/// If greater than 0, this property will make the view apply the given corner radius to
/// content in an efficient way.
@property (nonatomic) CGFloat contentCornerRadius UI_APPEARANCE_SELECTOR;

/// Defines how the corners will be inset from the receiver's bounds.
@property (nonatomic) UIEdgeInsets contentInsets UI_APPEARANCE_SELECTOR;

/// Indicates if the corner radius will be clipping the content. In this case
/// the layer corner radius will be used.
@property (nonatomic, getter = isClippingContent) BOOL clipContent;

@end
