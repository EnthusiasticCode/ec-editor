//
//  ECCodeViewBase.h
//  CodeView
//
//  Created by Nicola Peduzzi on 01/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ECTextRenderer.h"


@interface ECCodeViewBase : UIScrollView <ECTextRendererDelegate>

#pragma mark Advanced Initialization and Configuration

/// Initialize a codeview with external renderer and rendering queue.
/// The codeview initialized with this method will be set to not own the 
/// renderer and will use it only as a consumer.
- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer;

/// Renderer used in the codeview.
@property (nonatomic, readonly, strong) ECTextRenderer *renderer;

#pragma mark Managing Text Content

/// Set the text fot the control. This property is only used if textDatasource
/// is the code view itself.
@property (nonatomic, strong) NSString *text;

#pragma mark Styling Text Display

/// Text insets for the rendering.
@property (nonatomic) UIEdgeInsets textInsets;

/// Indicates if line numbers should be displayed according to line numbers properties.
@property (nonatomic, getter = isLineNumbersEnabled) BOOL lineNumbersEnabled;

/// The width to reserve for line numbers left inset. This value will not increase
/// the text insets; textInsets.left must be greater than this number.
@property (nonatomic) CGFloat lineNumbersWidth;

/// Font to be used for rendering line numbers
@property (nonatomic, strong) UIFont *lineNumbersFont;

/// Color to be used for rendering line numbers
@property (nonatomic, strong) UIColor *lineNumbersColor;

/// Add a layer pass that will be used by the renderer for overlays or underlays.
- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey;

// Removes a layer pass from the rendering process.
- (void)removePassLayerForKey:(NSString *)passKey;

@end


@interface ECCodeViewBase (ECTextRendererForwarding)

/// The datasource for the text displayed by the code view. Default is self.
/// If this datasource is not self, the text property will have no effect.
@property (nonatomic, strong) id<ECTextRendererDataSource> datasource;

/// Invalidate the text making the receiver redraw it.
- (void)updateAllText;

/// Invalidate a particular section of the text making the reveiver redraw it.
- (void)updateTextFromStringRange:(NSRange)originalRange toStringRange:(NSRange)newRange;

@end
