//
//  ACCodeFileMinimapView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECTextRenderer;


@interface ACCodeFileMinimapView : UIScrollView

@property (weak, nonatomic) ECTextRenderer *renderer;

#pragma mark - Managing Minimap Style

/// A view positioned as the background.
@property (strong, nonatomic) UIView *backgroundView;

/// The thickness of the uniform line representing a text line. Default 1, the minimum.
@property (nonatomic) CGFloat lineHeight;

/// The gap between two lines. Default 1, the minimum.
@property (nonatomic) CGFloat lineGap;

/// The default line color. If nil, black will be used.
@property (strong, nonatomic) UIColor *lineColor;

/// The color of the shadow for a line. Default nil meaning that lines will have no shadows.
@property (strong, nonatomic) UIColor *lineShadowColor;

@end
