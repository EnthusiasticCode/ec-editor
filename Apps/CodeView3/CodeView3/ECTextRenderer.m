//
//  ECTextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRenderer.h"
#import <CoreText/CoreText.h>

// Internal working notes: (outdated)
// - The renderer keeps an array of ordered framesetter informations:
//    > framesetter string range: the range of the total input used to
//      generate the framesetter. (order cryteria)
//    > framesetter: to be cached undefinetly untill clearCache message;
//    > frame: that cover the entire framesetter's text and is reused
//      when wrap size changes;
//    > frame info cache: that cache wrap sizes to frame infos;
//    > actual size: cache the actual size of rendered text.

#pragma mark TextSegmentFrame

@interface TextSegmentFrame : NSObject

@property (nonatomic, readonly) CTFrameRef frame;

@property (nonatomic, readonly) CGFloat wrapWidth;

@property (nonatomic, readonly) CGFloat height;

- (id)initWithFramesetter:(CTFramesetterRef)framesetter wrapWidth:(CGFloat)width;

- (void)releaseFrame;

@end

#pragma mark TextSegment

@interface TextSegment : NSObject {
@private
    // The framesetter for thi segment
    CTFramesetterRef framesetter;
    
    // A map of wrap width -> TextSegmentFrame
    NSCache *widthFramesCache;
}

/// String range (not line range) of the stirng used to generate the segment's framesetter.
@property (nonatomic, readonly) NSRange stringRange;

/// The current render width. Changing this property will make the segment to
/// generate a new frame if no one with this width is present in cache.
@property (nonatomic) CGFloat renderWrapWidth;

/// The actual render height of the whole string in the segment at the current
/// wrap width.
@property (nonatomic, readonly) CGFloat renderHeight;

/// Retrieve from cache or generate the frame that cover the entire framesetter's string.
@property (nonatomic, readonly) TextSegmentFrame *frameForCurrentWidth;

/// Generate a new framesetter and setup the stringRange property to return a range
/// with location and string length. The renders cache will be cleared and only 
/// the frame for the current wrap width will be generated.
- (void)setTextSegmentGeneratingString:(NSAttributedString *)string startingAtLocation:(NSUInteger)location;

/// Enumerate all the rendered lines in the text segment that intersect the given rect. 
/// The block to apply will receive the line and its bounds relative to the first rendered
/// line in this segment.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, BOOL *stop))block;

/// Release framesetters and frames to reduce space consumption. To release the frame
/// this method will actually clear the framse cache.
- (void)releaseFramesetterAndFrames;

@end

#pragma mark -
#pragma mark ECTextRenderer

@interface ECTextRenderer () {
@private
    BOOL delegateHasTextRendererDidChangeRenderForTextWithinRectToRect;
}
@end

#pragma mark Implementation

@implementation ECTextRenderer

@synthesize delegate, datasource, maximumLineCountPerSegment, lazyCaching, wrapWidth;

@end
