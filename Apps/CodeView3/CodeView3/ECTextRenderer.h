//
//  ECTextRenderer.h
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@class ECTextRenderer;

@protocol ECTextRendererDatasource <NSObject>
@required

/// An implementer of this method should return a string from the input
/// text that start at the given line location and that contain maximum
/// the given line count.
- (NSAttributedString *)textRenderer:(ECTextRenderer *)sender stringInLineRange:(NSRange *)lineRange;

@optional
/// When implemented, this delegate method should return the total number 
/// of lines in the input text. Lines that exceed the given maximum length
/// of characters shold be considered as multiple lines. If this method
/// returns 0 a different estime will be used.
- (NSUInteger)textRenderer:(ECTextRenderer *)sender estimatedTextLineCountOfLength:(NSUInteger)maximumLineLength;

@end

@protocol ECTextRendererDelegate <NSObject>
@optional

/// Called when the renderer update a part of its content.
- (void)textRenderer:(ECTextRenderer *)sender didChangeRenderForTextWithinRect:(CGRect)originalRect toRect:(CGRect)newRect;

@end

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
@property (nonatomic, assign) id <ECTextRendererDatasource> datasource;

/// Defines the preferred number of lines to use for one segment of input.
/// If this property is non-zero, input strings from the datasource will
/// be requested in segments when needed. This will reduce the ammount of 
/// text read and rendered at a time to improve speed and memory 
/// performance. Default value is 0.
@property (nonatomic) NSUInteger preferredLineCountPerSegment;

/// Invalidate the content making the renderer call back to its datasource
/// to refresh required strings.
- (void)invalidateAllText;

/// Invalidate a particular section of the content indicating how it changed.
/// This method will eventually make the renderer call back to it's datasource
/// to retrieve the modified content.
/// The original range can have length of 0 to indicate an insertion before the 
/// line; the new range can as well have a length of 0 to indicate deletion.
- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange;

#pragma mark Cacheing Behaviours

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

@end
