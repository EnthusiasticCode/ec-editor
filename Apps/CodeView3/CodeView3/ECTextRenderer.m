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

/// Count of string lines used to generate the segment's framesetter.
@property (nonatomic) NSUInteger lineCount;

/// Length of the string used to generate the segment's framesetter.
@property (nonatomic, readonly) NSUInteger stringLength;

/// The current render width. Changing this property will make the segment to
/// generate a new frame if no one with this width is present in cache.
@property (nonatomic) CGFloat renderWrapWidth;

/// The actual render height of the whole string in the segment at the current
/// wrap width.
@property (nonatomic, readonly) CGFloat renderHeight;

/// Retrieve from cache or generate the frame that cover the entire framesetter's string.
@property (nonatomic, readonly) TextSegmentFrame *frameForCurrentWidth;

/// A readonly property that returns true if the text segment requires generation.
@property (nonatomic, readonly) BOOL requireGeneration;

/// Generate a new framesetter and setup the stringRange and lineRange propety.
- (void)generateWithString:(NSAttributedString *)string 
                       havingLineCount:(NSUInteger)lineCount;

/// Enumerate all the rendered lines in the text segment that intersect the given rect. 
/// The rect should be relative to this segment coordinates.
/// The block to apply will receive the line and its bounds relative to the first rendered
/// line in this segment.
- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void(^)(CTLineRef line, CGRect lineBound, BOOL *stop))block;

/// Release framesetters and frames to reduce space consumption. To release the frame
/// this method will actually clear the framse cache.
- (void)removeFramesetterAndFrames;

@end

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize lineCount, stringLength, renderWrapWidth;

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

- (BOOL)requireGeneration
{
    return framesetter == NULL;
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
    [self removeFramesetterAndFrames];
    [widthFramesCache release];
    [super dealloc];
}

- (void)removeFramesetterAndFrames
{
    if (framesetter)
    {
        CFRelease(framesetter);
        framesetter = NULL;
    }
    [widthFramesCache removeAllObjects];
}

// TODO make a delegate to be sure to call this method if framsetter is NULL
- (void)generateWithString:(NSAttributedString *)string 
                       havingLineCount:(NSUInteger)count
{
    [self removeFramesetterAndFrames];
    framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    stringLength = [string length];
    lineCount = count;
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void (^)(CTLineRef, CGRect, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    BOOL stop = NO;
    CGFloat currentY = 0;
    CFArrayRef lines = CTFrameGetLines(self.frameForCurrentWidth.frame);
    CFIndex count = CFArrayGetCount(lines);
    CGFloat width, ascent, descent;
    CGRect bounds;
    for (CFIndex i = 0; i < count; ++i) 
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
    NSMutableArray *textSegments;
    
    BOOL delegateHasTextRendererDidChangeRenderForTextWithinRectToRect;
    BOOL datasourceHasTextRendererEstimatedTextLineCountOfLength;
}

- (void)cacheTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range;

@end


@implementation ECTextRenderer

#pragma mark Properties

@synthesize delegate, datasource, preferredLineCountPerSegment, lazyCaching, wrapWidth;

- (void)setDelegate:(id<ECTextRendererDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasTextRendererDidChangeRenderForTextWithinRectToRect = [delegate respondsToSelector:@selector(textRenderer:didChangeRenderForTextWithinRect:toRect:)];
}

- (void)setDatasource:(id<ECTextRendererDatasource>)aDatasource
{
    datasource = aDatasource;
    datasourceHasTextRendererEstimatedTextLineCountOfLength = [datasource respondsToSelector:@selector(textRenderer:estimatedTextLineCountOfLength:)];
    
    [self invalidateAllText];
}

- (void)setWrapWidth:(CGFloat)width
{
    wrapWidth = width;
    for (TextSegment *segment in textSegments) 
    {
        segment.renderWrapWidth = width;
    }
}

#pragma mark NSObject Methods

- (id)init 
{
    if ((self = [super init])) 
    {
        lazyCaching = YES;
        textSegments = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [textSegments release];
    [super dealloc];
}

#pragma mark Private Methods

- (void)cacheTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range
{
    if (!segment.requireGeneration)
        return;
    
    NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&range];
    if (string) 
    {
        [segment generateWithString:string havingLineCount:range.length];
    }
}

#pragma mark Public Methods

- (void)invalidateAllText
{
    [textSegments removeAllObjects];
    
    if (!lazyCaching) 
    {
        NSRange currentLineRange = NSMakeRange(0, preferredLineCountPerSegment);
        NSUInteger stringLocation = 0;
        NSAttributedString *string;
        while ((string = [datasource textRenderer:self stringInLineRange:&currentLineRange])) 
        {
            TextSegment *segment = [TextSegment new];
            [segment generateWithString:string 
                                    havingLineCount:currentLineRange.length];
            
            [textSegments addObject:segment];
            [segment release];
            
            currentLineRange.location += preferredLineCountPerSegment;
            stringLocation += [string length];
        }
    }
}

- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange
{
    NSUInteger currentLineLocation = 0;
    NSRange segmentRange, origInsersect, newIntersec;
    for (TextSegment *segment in textSegments) 
    {
        segmentRange = (NSRange){ currentLineLocation, segment.lineCount };
        
        origInsersect = NSIntersectionRange(originalRange, segmentRange);
        if (origInsersect.length > 0)
        {
            newIntersec = NSIntersectionRange(newRange, segmentRange);
            segmentRange.length += (newIntersec.length - origInsersect.length);
            segment.lineCount = segmentRange.length;
            // TODO if lineCount > 1.5 * preferred -> split or merge if * 0.5
            if (lazyCaching) 
            {
                [segment removeFramesetterAndFrames];
            }
            else
            {
                [self cacheTextSegment:segment withTextLineRange:segmentRange];
            }
        }
        
        currentLineLocation += segmentRange.length;
    }
}

- (void)clearCache
{
    for (TextSegment *segment in textSegments) 
    {
        [segment removeFramesetterAndFrames];
    }
}

- (CGRect)rectForIntegralNumberOfTextLinesWithinRect:(CGRect)rect allowGuessedResult:(BOOL)guessed
{
    __block CGRect result = CGRectZero;
    __block CGFloat meanLineHeight = 0;
    __block NSUInteger maxCharsForLine = 0;
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }

    // Count for existing segments
    CGFloat lastSegmentEnd = 0;
    NSRange currentLineRange = NSMakeRange(0, 0);
    CGRect currentRect = rect;
    CGFloat currentRectEnd;
    for (TextSegment *segment in textSegments)
    {
        if (guessed && segment.requireGeneration)
            break;
        
        currentLineRange.length = segment.lineCount;
        [self cacheTextSegment:segment withTextLineRange:currentLineRange];
        currentLineRange.location += currentLineRange.length;
        
        currentRect.origin.y -= lastSegmentEnd;
        if (currentRect.origin.y < 0) 
        {
            currentRect.size.height += currentRect.origin.y;
            currentRect.origin.y = 0;
        }
        currentRectEnd = CGRectGetMaxY(currentRect);
        if (currentRectEnd <= 0)
            return result;
        
        lastSegmentEnd += segment.renderHeight;
        if (rect.origin.y > lastSegmentEnd)
            continue;
        
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(CTLineRef line, CGRect lineBound, BOOL *stop) {
            result.size.width = MAX(result.size.width, lineBound.size.width);
            result.size.height += lineBound.size.height;
            
            if (meanLineHeight > 0) 
            {
                meanLineHeight = (meanLineHeight + lineBound.size.height) / 2.0;
            }
            else
            {
                meanLineHeight = lineBound.size.height;
            }
            maxCharsForLine = MAX(maxCharsForLine, CTLineGetGlyphCount(line));
        }];
    }
    
    // Guess remaining result
    if (guessed && lastSegmentEnd < CGRectGetMaxY(rect)) 
    {
        // Create datasource enabled guess
        if (datasourceHasTextRendererEstimatedTextLineCountOfLength) 
        {
            // Ensure to have a mean line height or generate it
            if (meanLineHeight == 0) 
            {
                NSRange tempRange = NSMakeRange(0, 1);
                NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&tempRange];
                if (string) 
                {
                    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)string);
                    CGFloat width, ascent, descent;
                    width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
                    meanLineHeight = ascent + descent;
                    maxCharsForLine = wrapWidth * CTLineGetGlyphCount(line) / width;
                    CFRelease(line);
                }
                else
                {
                    // TODO use ctfontgetascent?
                    meanLineHeight = 13.0;
                    maxCharsForLine = wrapWidth / 10.0;
                }
            }
            
            // Estime
            NSUInteger totalLines = [datasource textRenderer:self estimatedTextLineCountOfLength:maxCharsForLine];
            totalLines -= currentLineRange.location;
            result.size.height += totalLines * meanLineHeight;
        }
        else
        {
            // TODO CTFramesetterSuggestFrameSizeWithConstraints
        }
    }
    
    return result;
}

- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context
{
    // Sanitize input
    if (!context)
        return;
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    
    // Setup rendering transformations
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextPosition(context, 0, 0);
    CGContextScaleCTM(context, 1, -1);
    
    // Enumerate used text segments
    CGFloat lastSegmentEnd = 0, currentRectEnd;
    CGRect currentRect = rect;
    NSRange currentLineRange = NSMakeRange(0, 0);
    for (TextSegment *segment in textSegments)
    {
        // Generate if needed
        currentLineRange.length = segment.lineCount;
        [self cacheTextSegment:segment withTextLineRange:currentLineRange];
        currentLineRange.location += currentLineRange.length;
        
        // Adjust rect to current segment relative coordinates
        currentRect.origin.y -= lastSegmentEnd;
        if (currentRect.origin.y < 0)
        {
            currentRect.size.height += currentRect.origin.y;
            currentRect.origin.y = 0;
        }
        currentRectEnd = CGRectGetMaxY(currentRect);
        if (currentRectEnd <= 0)
            return;
        
        // Skip not intersected segments
        lastSegmentEnd += segment.renderHeight;
        if (rect.origin.y > lastSegmentEnd)
            continue;
        
        // Draw needed lines from this segment
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(CTLineRef line, CGRect lineBound, BOOL *stop) {
            // Require adjustment in rendering for first partial line
            if (lineBound.origin.y < currentRect.origin.y) 
            {
                CGContextTranslateCTM(context, 0, currentRect.origin.y - lineBound.origin.y);
            }
            // Positioning and rendering
            CGContextTranslateCTM(context, 0, -lineBound.size.height);
            CTLineDraw(line, context);
            CGContextTranslateCTM(context, -lineBound.size.width, 0);
        }];
    }
}

@end
