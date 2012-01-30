//
//  ShapeBackgroundPopoverView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIPopoverBackgroundView.h>

@interface ShapePopoverBackgroundView : UIPopoverBackgroundView

#pragma mark Style

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;

/// Specify a shadow offset to apply as the layer shadow offset that will be
/// automaticaly oriented based on the arrow direction.
@property (nonatomic) CGSize shadowOffsetForArrowDirectionUpToAutoOrient UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat shadowOpacity UI_APPEARANCE_SELECTOR;

@property (nonatomic) CGFloat shadowRadius UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) UIColor *strokeColor UI_APPEARANCE_SELECTOR;

#pragma mark Arrow

@property (nonatomic) CGFloat arrowCornerRadius UI_APPEARANCE_SELECTOR;

@end


@interface ShapePopoverController : UIPopoverController
@end
