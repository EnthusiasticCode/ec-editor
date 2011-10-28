//
//  ECTextRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "ECRectSet.h"

@class ECTextRenderer;
@class ECTextRendererLine;


/// Block used to apply an overlay or underlay pass to the rendering.
/// The block should draw on the given context and inside the lineBounds rect which
/// is relative to the current context state. Bounds will account for text insets.
/// The CTLine can be used to retireve offsets inside the line with CTLineGetOffsetForStringIndex.
/// String range and line number are relative to the whole text managed by the renderer.
typedef void (^ECTextRendererLayerPass)(CGContextRef context, ECTextRendererLine *line, CGRect lineBounds, NSRange stringRange, NSUInteger lineNumber);


@protocol ECTextRendererDelegate <NSObject>
@optional

/// Called when the renderer update a part of its content.
- (void)textRenderer:(ECTextRenderer *)sender didInvalidateRenderInRect:(CGRect)rect;

@end


@protocol ECTextRendererDataSource <NSObject>
@required

/// Returns the length of the source string.
- (NSUInteger)stringLengthForTextRenderer:(ECTextRenderer *)sender;

/// An implementer of this method should return a string from the input
/// text in the given string range. If the range length is 0
/// the caller is expected to get all the remaining string.
- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender attributedStringInRange:(NSRange)stringRange;

@end


/// A class that present a text retrieved by a dataSource ready to be drawn
/// fully or partially. The user of an instance of this class should 
/// consider as if an etire text wrapped at the given wrap width is 
/// ready to be rendered.
@interface ECTextRenderer : NSObject

#pragma mark Managing Text Input Data

/// A delegate that will recevie notifications from the text renderer.
@property (nonatomic, weak) id <ECTextRendererDelegate> delegate;

/// The dataSource to retrieve the text to render. It has to conform to
/// \c ECTextRendererDataSource protocol.
@property (nonatomic, weak) id <ECTextRendererDataSource> dataSource;

/// Defines the maximum number of characters to use for one rendering segment.
/// If this property is non-zero, input strings from the dataSource will
/// be requested in segments when needed. This will reduce the ammount of 
/// text read and rendered at a time to improve speed and memory 
/// performance. Default value is 0.
@property (nonatomic) NSUInteger maximumStringLenghtPerSegment;

/// Invalidate the content making the renderer call back to its dataSource
/// to refresh required strings.
- (void)updateAllText;

/// Invalidate a particular section of the content indicating how it changed.
/// This method will eventually make the renderer call back to it's dataSource
/// to retrieve the modified content.
/// The original range can have length of 0 to indicate an insertion before the 
/// line; the new range can as well have a length of 0 to indicate deletion.
- (void)updateTextFromStringRange:(NSRange)originalRange toStringRange:(NSRange)newRange;

#pragma mark Customizing Rendering

/// The width to use for the rendering canvas.
/// Changing this property will make the renderer to invalidate it's content.
@property (nonatomic) CGFloat renderWidth;

/// Returns the current height of the rendered text. This property may change it's
/// value based on the lazy loading process of the renderer.
/// A user can observe this property to receive updates on the changing height.
@property (nonatomic, readonly) CGFloat renderHeight;

/// Insets to give to the text in the rendering area.
@property (nonatomic) UIEdgeInsets textInsets;

/// An array of ECTextRendererLayerPass that will be applied in order to every
/// line before rendering the actual text line.
@property (nonatomic, copy) NSArray *underlayRenderingPasses;

/// An array of ECTextRendererLayerPass that will be applied in order to every
/// line after rendering the actual text line.
@property (nonatomic, copy) NSArray *overlayRenderingPasses;

#pragma mark Rendering Content

/// Given a rect in the rendered text space, this method return a centered
/// and resized to fit an integral number of lines present in that original
/// rect. The result can be computed faster but inpreciselly if the guessed
/// flag is set to YES.
//- (CGRect)rectForIntegralNumberOfTextLinesWithinRect:(CGRect)rect allowGuessedResult:(BOOL)guessed;

/// Convenience function to enumerate throught all lines (indipendent from text segment)
/// contained in the given rect relative to the rendered text space.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, NSRange stringRange, BOOL *stop))block;

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
- (ECRectSet *)rectsForStringRange:(NSRange)range limitToFirstLine:(BOOL)limit;

/// Move the given position in the given direction by the given offset visually.
/// Returns the new index in the source text or NSUIntegerMax if no position 
/// has been returned. In some cases the returned position may be greater than
/// the source text lenght.
- (NSUInteger)positionFromPosition:(NSUInteger)position inLayoutDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset;

@end


/// A class used to provide line informations on line enumeration
@interface ECTextRendererLine : NSObject

@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat ascent;
@property (nonatomic) CGFloat descent;
@property (nonatomic, readonly) CGFloat height;
@property (nonatomic, readonly) CGSize size;

/// Indicates if the line text has a new line meaning that it will advance the 
/// actual text line count.
@property (nonatomic) BOOL hasNewLine;

- (void)drawInContext:(CGContextRef)context;

/// Return a rect relative to the string start position containing the given 
/// substirng character range. The string range has to be relative to the string.
- (CGRect)boundsForSubstringInRange:(NSRange)stringRange;

@end
