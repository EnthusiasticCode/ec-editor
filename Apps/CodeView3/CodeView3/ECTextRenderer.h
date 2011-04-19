//
//  ECTextRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "ECTextRendererDataSource.h"
#import "ECTextRendererDelegate.h"


/// A class that present a text retrieved by a datasource ready to be drawn
/// fully or partially. The user of an instance of this class should 
/// consider as if an etire text wrapped at the given wrap width is 
/// ready to be rendered.
@interface ECTextRenderer : NSObject

#pragma mark Managing Text Input Data

/// A delegate that will recevie notifications from the text renderer.
@property (nonatomic, assign) id <ECTextRendererDelegate> delegate;

/// The datasource to retrieve the text to render. It has to conform to
/// \c ECTextRendererDatasource protocol.
@property (nonatomic, assign) id <ECTextRendererDataSource> datasource;

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

/// Indicates if the caching of rendering informations should happen lazely 
/// or immediatly after a datasource is set. Defaults is YES.
@property (nonatomic) BOOL lazyCaching;

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

/// Renders the content text contained in the given rect to the specified 
/// context. The given context will not be modified prior rendering. Lines
/// will be drawn with the current context transformation and context will
/// be left at the beginning of the next non redered line.
- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context;

#pragma mark Retreiving Geometry to Text Mapping

/// Returns the closest string location to the given graphical point relative
/// to the rendered text space where the first line is at 0, 0.
/// A limit of character in which to search in is also used to limit the results.
- (NSUInteger)closestStringLocationToPoint:(CGPoint)point withinStringRange:(NSRange)range;

/// Returns the bounding rect for all the characters in the given range of text.
/// If the range is in a single line, the bounding box of of the range is returned;
/// otherwhise it will be a bounding box of the union of lines interested by the range.
- (CGRect)boundsForStringRange:(NSRange)range;

@end
