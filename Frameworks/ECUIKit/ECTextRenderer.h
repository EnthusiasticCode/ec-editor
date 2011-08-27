//
//  ECTextRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import "ECRectSet.h"

@class ECTextRenderer;
@class ECTextRendererLine;

@protocol ECTextRendererDelegate <NSObject>
@optional

/// Called when the renderer update a part of its content.
- (void)textRenderer:(ECTextRenderer *)sender invalidateRenderInRect:(CGRect)rect;

@end


@protocol ECTextRendererDataSource <NSObject>
@required

/// An implementer of this method should return a string from the input
/// text that start at the given line location and that contain maximum
/// the given line count.
/// lineRange in input is the desired range of lines, in ouput its length
/// should be less or equal to the input value to indicate how many lines 
/// have actually been return.
/// endOfString is an output parameter that should be set to YES if the 
/// requested line range contains the end of the source string.
/// The returned string should contain an additional new line at the end of
/// the source text for optimal rendering.
- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange endOfString:(BOOL *)endOfString;

@optional
/// When implemented, this delegate method should return the total number 
/// of lines in the input text. Lines that exceed the given maximum length
/// of characters shold be considered as multiple lines. If this method
/// returns 0 a different estime will be used.
- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength;

@end


/// A class that present a text retrieved by a datasource ready to be drawn
/// fully or partially. The user of an instance of this class should 
/// consider as if an etire text wrapped at the given wrap width is 
/// ready to be rendered.
@interface ECTextRenderer : NSObject

#pragma mark Managing Text Input Data

/// A delegate that will recevie notifications from the text renderer.
@property (nonatomic, weak) id <ECTextRendererDelegate> delegate;

/// The datasource to retrieve the text to render. It has to conform to
/// \c ECTextRendererDatasource protocol.
@property (nonatomic, weak) id <ECTextRendererDataSource> datasource;

/// Defines the preferred number of lines to use for one segment of input.
/// If this property is non-zero, input strings from the datasource will
/// be requested in segments when needed. This will reduce the ammount of 
/// text read and rendered at a time to improve speed and memory 
/// performance. Default value is 0.
@property (nonatomic) NSUInteger preferredLineCountPerSegment;

/// Invalidate the content making the renderer call back to its datasource
/// to refresh required strings.
- (void)updateAllText;

/// Invalidate a particular section of the content indicating how it changed.
/// This method will eventually make the renderer call back to it's datasource
/// to retrieve the modified content.
/// The original range can have length of 0 to indicate an insertion before the 
/// line; the new range can as well have a length of 0 to indicate deletion.
- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange;

#pragma mark Caching Behaviours

/// Use this method to clear the rendered cache if memory usage start to be 
/// a problem.
- (void)clearCache;

#pragma mark Managing Rendering Behaviours

/// The width to use to wrap the text. Changing this property will make the
/// renderer to invalidate it's content.
@property (nonatomic) CGFloat wrapWidth;

/// Returns the estimated height for the current content at the current wrap
/// width. A user can observe this property to receive updates on the estimation.
@property (nonatomic, readonly) CGFloat estimatedHeight;

/// Given a rect in the rendered text space, this method return a centered
/// and resized to fit an integral number of lines present in that original
/// rect. The result can be computed faster but inpreciselly if the guessed
/// flag is set to YES.
- (CGRect)rectForIntegralNumberOfTextLinesWithinRect:(CGRect)rect allowGuessedResult:(BOOL)guessed;

#pragma mark Rendering Content

/// Convenience function to enumerate throught all lines (indipendent from text segment)
/// contained in the given rect relative to the rendered text space.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stop))block;

/// Renders the content text contained in the given rect to the specified 
/// context. The given context will not be modified prior rendering. Lines
/// will be drawn with the current context transformation and context will
/// be left at the beginning of the next non redered line.
/// A block can be specified and it will be called for each rendered line
/// with the current line number (not considering wraps), after the context 
/// has been positioned to draw the current partial line.
- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context withLineBlock:(void(^)(ECTextRendererLine *line, NSUInteger lineNumber))block;

#pragma mark Retreiving Geometry to Text Mapping

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

@end
