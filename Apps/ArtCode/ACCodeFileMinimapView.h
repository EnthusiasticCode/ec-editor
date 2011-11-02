//
//  ACCodeFileMinimapView.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 02/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACCodeFileMinimapView;

@protocol ACCodeFileMinimapViewDataSource <NSObject>
@required

/// Returns the number of lines that the minimap has to display.
- (NSUInteger)numberOfLinesForCodeFileMinimapView:(ACCodeFileMinimapView *)minimapView;

/// Returns the length of the line at the given index as a number between 0 and 1, where 1 is the 
/// length of the longest line. If given, the lineColor will be used instead of the default color
/// for the line.
- (CGFloat)codeFileMinimapView:(ACCodeFileMinimapView *)minimapView lenghtOfLineAtIndex:(NSUInteger)lineIndex applyColor:(UIColor **)lineColor;

@end

@interface ACCodeFileMinimapView : UIScrollView

#pragma mark - Providing Data

@property (weak, nonatomic) id<ACCodeFileMinimapViewDataSource> dataSource;

- (void)reloadAllData;

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
