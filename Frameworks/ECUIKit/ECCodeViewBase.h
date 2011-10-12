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

@class ECCodeViewBase;

@protocol ECCodeViewBaseDataSource <NSObject>
@required

/// When implemented return the length of the text in the datasource.
- (NSUInteger)textLength;

/// Returns the string range from a given line range.
/// The provided line range sould have it's length modified to the actual number of lines returned.
- (NSRange)codeView:(ECCodeViewBase *)codeView stringRangeForLineRange:(NSRange *)lineRange;

/// Return the substring in the given range. Used to implement
/// \c UITextInput methods.
- (NSAttributedString *)codeView:(ECCodeViewBase *)codeView stringInRange:(NSRange)range;

@end


typedef void (^LineNumberRenderingBlock)(CGContextRef context, CGRect lineNumberBounds, CGFloat baseline, NSUInteger lineNumber, BOOL isWrappedLine);


@interface ECCodeViewBase : UIScrollView <ECTextRendererDelegate, ECTextRendererDataSource>

#pragma mark Advanced Initialization and Configuration

/// Initialize a codeview with external renderer and rendering queue.
/// The codeview initialized with this method will be set to not own the 
/// renderer and will use it only as a consumer.
- (id)initWithFrame:(CGRect)frame renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue;

/// Renderer used in the codeview.
@property (nonatomic, readonly, strong) ECTextRenderer *renderer;

/// Queue where renderer should be used.
@property (nonatomic, strong) NSOperationQueue *renderingQueue;

#pragma mark Providing Source Data

/// The datasource for the text displayed by the code view. Default is self.
/// If this datasource is not self, the text property will have no effect.
@property (nonatomic, strong) id<ECCodeViewBaseDataSource> datasource;

#pragma mark Managing Text Content

/// Set the text fot the control. This property is only used if textDatasource
/// is the code view itself.
@property (nonatomic, strong) NSString *text;

/// Invalidate the text making the receiver redraw it.
- (void)updateAllText;

/// Invalidate a particular section of the text making the reveiver redraw it.
- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange;

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

/// Provide a block that will be called for each line and may render the number of the line
/// in the given context. The block receives: the context in which to draw, bounds in which
/// the drawing may be bounded, a baseline relative to the bounds y to align with the text
/// line, the number of the line that will be drawn and a value indicating if the requested
/// line is a wrapped line.
@property (nonatomic, copy) LineNumberRenderingBlock lineNumberRenderingBlock;

/// Add a layer pass that will be used by the renderer for overlays or underlays.
- (void)addPassLayerBlock:(ECTextRendererLayerPass)block underText:(BOOL)isUnderlay forKey:(NSString *)passKey;

// Removes a layer pass from the rendering process.
- (void)removePassLayerForKey:(NSString *)passKey;

@end
