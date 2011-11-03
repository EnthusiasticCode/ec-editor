//
//  ACCodeFileMinimapView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileMinimapView, ECTextRenderer, ECTextRendererLine;

enum {
    ACCodeFileMinimapLineDecorationNone,
    ACCodeFileMinimapLineDecorationDisc,
    ACCodeFileMinimapLineDecorationSquare
};

typedef NSInteger ACCodeFileMinimapLineDecoration;

@protocol ACCodeFileMinimapViewDelegate <UIScrollViewDelegate>
@optional

/// Returns if the given line should be rendered by the minimap with the given color, decoration and decoration color.
/// All this last three parameters can be assigned to change the way the line is rendered.
- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldRenderLine:(ECTextRendererLine *)line number:(NSUInteger)lineNumber withColor:(UIColor **)lineColor deocration:(ACCodeFileMinimapLineDecoration *)decoration decorationColor:(UIColor **)decorationColor;

/// Called when the user changes the selection rectangle from the minimap.
- (BOOL)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView shouldChangeSelectionRectangle:(CGRect)newSelection;

@end


@interface ACCodeFileMinimapView : UIScrollView

#pragma mark - Providing Content

@property (weak, nonatomic) id<ACCodeFileMinimapViewDelegate> delegate;

/// The renderer to use to produce the minimap.
@property (weak, nonatomic) ECTextRenderer *renderer;

#pragma mark - Selection Rectangle

/// The selection rectangle espressed in renderer coordinates. Set to CGRectNull to remove the selection.
/// This property should be observed to respont to the user moving the selection in the minimap.
@property (nonatomic) CGRect selectionRectangle;

/// A view used to mark the selection if any.
@property (strong, nonatomic) UIView *selectionView;

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
