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

/// Set the text fot the control. This property is only used if textDataSource
/// is the code view itself.
@property (nonatomic, strong) NSString *text;

/// Text insets for the rendering.
@property (nonatomic) UIEdgeInsets textInsets;

#pragma mark Code Display Enhancements

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

/// Removes a layer pass from the rendering process.
- (void)removePassLayerForKey:(NSString *)passKey;

/// Scrolls the given range to be visible and flashes it for a brief moment to draw user attention on it.
- (void)flashTextInRange:(NSRange)textRange;

@end


@interface ECCodeViewBase (ECTextRendererForwarding)

/// The dataSource for the text displayed by the code view. Default is self.
/// If this dataSource is not self, the text property will have no effect.
@property (nonatomic, strong) id<ECTextRendererDataSource> dataSource;

/// Invalidate the text making the receiver redraw it.
- (void)updateAllText;

/// Invalidate a particular section of the text making the reveiver redraw it.
- (void)updateTextFromStringRange:(NSRange)originalRange toStringRange:(NSRange)newRange;

@end


/// View used to flash a text range.
@interface ECCodeFlashView : UIView

@property (nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;

/// Flashes the receiver by showing and increasing it's size for half of the given duration
/// and than reversing the animation for the remaining half. The receiver will be added
/// and removed automatically to the given view.
- (void)flashInRect:(CGRect)rect view:(UIView *)view withDuration:(NSTimeInterval)duration;

@end
