//
//  ACCodeFileMinimapView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileMinimapView, ECTextRenderer, ECTextRendererLine;

@protocol ACCodeFileMinimapViewDelegate <UIScrollViewDelegate>
@optional

- (UIColor *)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView colorForRendererLine:(ECTextRendererLine *)line number:(NSUInteger)lineNumber;

@end


@interface ACCodeFileMinimapView : UIScrollView

#pragma mark - Providing Content

@property (weak, nonatomic) id<ACCodeFileMinimapViewDelegate> delegate;

/// The renderer to use to produce the minimap.
@property (weak, nonatomic) ECTextRenderer *renderer;

#pragma mark - Managing Minimap Style

/// A view positioned as the background.
@property (strong, nonatomic) UIView *backgroundView;

/// An inset applied to the decoration side of the minimap.
@property (nonatomic) CGFloat lineDecorationInset;

/// The thickness of the uniform line representing a text line. Default 1, the minimum.
@property (nonatomic) CGFloat lineThickness;

/// The default line color. If nil, black will be used.
@property (strong, nonatomic) UIColor *lineDefaultColor;

/// The color of the shadow for a line. Default nil meaning that lines will have no shadows.
@property (strong, nonatomic) UIColor *lineShadowColor;

@end
