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

#pragma mark -
#pragma mark TextSegmentFrame

@interface TextSegmentFrame : NSObject //<NSDiscardableContent>

@property (nonatomic, readonly) CTFrameRef frame;

@property (nonatomic, readonly) CGFloat wrapWidth;

@property (nonatomic, readonly) CGFloat height;

- (id)initWithFramesetter:(CTFramesetterRef)framesetter wrapWidth:(CGFloat)width;

@end

@implementation TextSegmentFrame

@synthesize frame, wrapWidth, height;

- (id)initWithFramesetter:(CTFramesetterRef)framesetter wrapWidth:(CGFloat)width
{
    if ((self = [super init]) && framesetter)
    {
        // Create path
        wrapWidth = width;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, (CGRect){ CGPointZero, { width, CGFLOAT_MAX } });
        
        // Create frame
        frame = CTFramesetterCreateFrame(framesetter, (CFRange){ 0, 0 }, path, NULL);
        CGPathRelease(path);
        
        // Calculate actual height
        height = 0;
        CFArrayRef lines = CTFrameGetLines(frame);
        CFIndex lineCount = CFArrayGetCount(lines);
        CTLineRef line;
        CGFloat ascent, descent;
        for (CFIndex i = 0; i < lineCount; ++i)
        {
            line = CFArrayGetValueAtIndex(lines, i);
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            height += ascent + descent;
        }
    }
    return self;
}

- (void)dealloc
{
    if (frame) 
    {
        CFRelease(frame);
    }
    [super dealloc];
}

//- (BOOL)beginContentAccess
//{
//    return frame != NULL;
//}
//
//- (void)endContentAccess
//{
//    
//}
//
//- (void)discardContentIfPossible
//{
//    if (frame) 
//    {
//        CFRelease(frame);
//        frame = NULL;
//    }
//}
//
//- (BOOL)isContentDiscarded
//{
//    return frame == NULL;
//}

@end

#pragma mark -
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
/// The rect should be relative to this segment coordinates.
/// The block to apply will receive the line and its bounds relative to the first rendered
/// line in this segment.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, BOOL *stop))block;

/// Release framesetters and frames to reduce space consumption. To release the frame
/// this method will actually clear the framse cache.
- (void)releaseFramesetterAndFrames;

@end

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize stringRange, renderWrapWidth;

- (void)setRenderWrapWidth:(CGFloat)width
{
    if (renderWrapWidth != width) 
    {
        renderWrapWidth = width;
        [widthFramesCache removeAllObjects];
    }
}

- (TextSegmentFrame *)frameForCurrentWidth
{
    NSNumber *wrapWidth = [NSNumber numberWithFloat:renderWrapWidth];
    TextSegmentFrame *segmentFrame = [widthFramesCache objectForKey:wrapWidth];
    if (!segmentFrame) 
    {
        if (!framesetter)
            return nil;
        segmentFrame = [[TextSegmentFrame alloc] initWithFramesetter:framesetter wrapWidth:renderWrapWidth];
        [widthFramesCache setObject:segmentFrame forKey:wrapWidth];
    }
    return segmentFrame;
}

- (CGFloat)renderHeight
{
    return self.frameForCurrentWidth.height;
}

#pragma mark TextSegment Methods

- (id)init 
{
    if ((self = [super init])) 
    {
        widthFramesCache = [NSCache new];
    }
    return self;
}

- (void)dealloc
{
    [self releaseFramesetterAndFrames];
    [widthFramesCache release];
    [super dealloc];
}

- (void)releaseFramesetterAndFrames
{
    if (framesetter) 
    {
        CFRelease(framesetter);
        framesetter = NULL;
    }
    [widthFramesCache removeAllObjects];
}

// TODO make a delegate to be sure to call this method if framsetter is NULL
- (void)setTextSegmentGeneratingString:(NSAttributedString *)string startingAtLocation:(NSUInteger)location
{
    [self releaseFramesetterAndFrames];
    framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    stringRange = NSMakeRange(location, [string length]);
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(CTLineRef, CGRect, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    BOOL stop = NO;
    CGFloat currentY = 0;
    CFArrayRef lines = CTFrameGetLines(self.frameForCurrentWidth.frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGFloat width, ascent, descent;
    CGRect bounds;
    for (CFIndex i = 0; i < lineCount; ++i) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        bounds = CGRectMake(0, currentY, width, ascent + descent);
        if (currentY + bounds.size.height > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            //
            block(line, bounds, &stop);
            if (stop) break;
        }
        currentY += bounds.size.height;
    }
}

@end

#pragma mark -
#pragma mark ECTextRenderer

@interface ECTextRenderer () {
@private
    BOOL delegateHasTextRendererDidChangeRenderForTextWithinRectToRect;
}
@end


@implementation ECTextRenderer

#pragma mark Properties

@synthesize delegate, datasource, maximumLineCountPerSegment, lazyCaching, wrapWidth;

#pragma mark Public Methods

@end
