//
//  TextRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "RectSet.h"

extern NSString * const TextRendererRunBackgroundColorAttributeName;
extern NSString * const TextRendererRunOverlayBlockAttributeName;
extern NSString * const TextRendererRunUnderlayBlockAttributeName;

/// Indicates a block to be used to render a run. The value of this attribute must be a TextRendererRunBlock. If not specified the default CTRunDraw will be called instead.
extern NSString * const TextRendererRunDrawBlockAttributeName;

typedef void (^TextRendererRunBlock)(CGContextRef context, CTRunRef run, CGRect runRect, CGFloat baselineOffset);

@class TextRenderer;
@class TextRendererLine;

/// Block used to apply an overlay or underlay pass to the rendering.
/// The block should draw on the given context and inside the lineBounds rect which
/// is relative to the current context state. Bounds will account for text insets.
/// The CTLine can be used to retireve offsets inside the line with CTLineGetOffsetForStringIndex.
/// String range and line number are relative to the whole text managed by the renderer.
typedef void (^TextRendererLayerPass)(CGContextRef context, TextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber);


@protocol TextRendererDelegate <NSObject>
@optional

/// Called when the renderer update a part of its content.
- (void)textRenderer:(TextRenderer *)sender willInvalidateRenderInRect:(CGRect)rect;

@end



/// A class that present a text retrieved by a dataSource ready to be drawn
/// fully or partially. The user of an instance of this class should 
/// consider as if an etire text wrapped at the given wrap width is 
/// ready to be rendered.
@interface TextRenderer : NSObject

#pragma mark Managing Text Input Data

/// The text to be used to render. It is mutable to avoid copying, that has been found too slow in profiling.
@property (nonatomic, strong) NSMutableAttributedString *text;

/// A dictionary containing default text attributes that are applied to add an 
/// additional tailing new-line.
@property (nonatomic, strong) NSDictionary *defaultTextAttributes;

/// A delegate that will recevie notifications from the text renderer.
@property (nonatomic, weak) id <TextRendererDelegate> delegate;

/// Defines the maximum number of characters to use for one rendering segment.
/// If this property is non-zero, input strings from the dataSource will
/// be requested in segments when needed. This will reduce the ammount of 
/// text read and rendered at a time to improve speed and memory 
/// performance. Default value is 0.
@property (nonatomic) NSUInteger maximumStringLenghtPerSegment;

#pragma mark Customizing Rendering

/// The width to use for the rendering canvas.
/// Changing this property will make the renderer to invalidate it's content.
@property (nonatomic) CGFloat renderWidth;

/// Returns the current height of the rendered text. This property may change it's
/// value based on the lazy loading process of the renderer.
/// A user can observe this property to receive updates on the changing height.
@property (nonatomic, readonly) CGFloat renderHeight;

/// Like render height but only include height of rendered text without insets.
@property (nonatomic, readonly) CGFloat renderTextHeight;

/// Indicates if the render height is completely computed or there are still non-generated text segments.
@property (nonatomic, readonly, getter = isRenderHeightFinal) BOOL renderHeightFinal;

/// Insets to give to the text in the rendering area.
@property (nonatomic) UIEdgeInsets textInsets;

/// An array of TextRendererLayerPass that will be applied in order to every
/// line before rendering the actual text line.
@property (nonatomic, copy) NSArray *underlayRenderingPasses;

/// An array of TextRendererLayerPass that will be applied in order to every
/// line after rendering the actual text line.
@property (nonatomic, copy) NSArray *overlayRenderingPasses;

#pragma mark Accessing Renered Lines

/// Convenience function to enumerate throught all lines (indipendent from text segment)
/// contained in the given rect relative to the rendered text space.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineYOffset, NSRange stringRange, BOOL *stop))block;

#pragma mark Rendering Content

/// Indicate that the whole content should be re-rendered before the next draw.
/// Returns the corresponding rect that will be updated on the next drawing.
/// The same rect is passed to the delegate.
- (CGRect)setNeedsUpdate;

/// Indicate that part of the text content should be re-rendered,
/// Returns the corresponding rect that will be updated on the next drawing.
/// The same rect is passed to the delegate.
- (CGRect)setNeedsUpdateInTextRange:(NSRange)range;

/// Renders the content text contained in the given rect to the specified 
/// context. The given context will not be modified prior rendering. Lines
/// will be drawn with the current context transformation and context will
/// be left at the beginning of the next non redered line.
/// A block can be specified and it will be called for each rendered line
/// with the current line number (not considering wraps), after the context 
/// has been positioned to draw the current partial line.
- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context;

#pragma mark Retreiving Geometry to Text Mapping

/// Convert a rect relative to the text to one that account for text insets.
- (CGRect)convertFromTextRect:(CGRect)rect;
- (CGPoint)convertFromTextPoint:(CGPoint)point;

/// Convert a rect in rendered image coordinates to one relative to the text only.
/// Removes data source text insets.
- (CGRect)convertToTextRect:(CGRect)rect;
- (CGPoint)convertToTextPoint:(CGPoint)point;

/// Returns the closest string location to the given graphical point relative
/// to the rendered text space where the first line is at 0, 0.
/// A limit of character in which to search in is also used to limit the results.
- (NSUInteger)closestStringLocationToPoint:(CGPoint)point withinStringRange:(NSRange)range;

/// Returns the rects for all the characters in the given range of rendered text.
- (RectSet *)rectsForStringRange:(NSRange)range limitToFirstLine:(BOOL)limit;

/// Move the given position in the given direction by the given offset visually.
/// Returns the new index in the source text or NSUIntegerMax if no position 
/// has been returned. In some cases the returned position may be greater than
/// the source text lenght.
- (NSUInteger)positionFromPosition:(NSUInteger)position inLayoutDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset;

@end


/// A class used to provide line informations on line enumeration
@interface TextRendererLine : NSObject

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat ascent;
@property (nonatomic) CGFloat descent;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGSize size;

/// Indicates if the line is a truncation of a full text line.
/// if a text line is truncated in two, only the second part will be marked as isTruncation.
@property (nonatomic) BOOL isTruncation;

- (void)drawInContext:(CGContextRef)context;

/// Return a rect relative to the string start position containing the given 
/// substirng character range. The string range has to be relative to the string.
- (CGRect)boundsForSubstringInRange:(NSRange)stringRange;

@end
