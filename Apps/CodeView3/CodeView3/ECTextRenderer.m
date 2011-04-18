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
#pragma mark TextSegment

#define HEIGHT_CACHE_SIZE (3)

@interface TextSegment : NSObject {
@private
    // The framesetter for thi segment
    CTFramesetterRef framesetter;
    CTFrameRef *frameCache;
    
    // Cache of heights for wrap widths
    struct { CGFloat wrapWidth; CGFloat height; } heightCache[HEIGHT_CACHE_SIZE];
}

- (id)initWithFrameCache:(CTFrameRef *)cache;

@property (nonatomic, readonly) CTFrameRef frame;

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

/// A readonly property that returns true if the text segment requires generation.
@property (nonatomic, readonly) BOOL requireGeneration;

/// Generate a new framesetter and setup the stringRange and lineRange propety.
- (void)generateWithString:(NSAttributedString *)string havingLineCount:(NSUInteger)lineCount;

/// Enumerate all the rendered lines in the text segment that intersect the given rect. 
/// The rect should be relative to this segment coordinates.
/// The block to apply will receive the line and its bounds relative to the first rendered
/// line in this segment.
- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void(^)(CTLineRef line, CGRect lineBound, CGFloat baseline, BOOL *stop))block 
                               reverse:(BOOL)reverse;

/// Release framesetters and frames to reduce space consumption. To release the frame
/// this method will actually clear the framse cache.
- (void)removeFramesetter;

@end

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize frame, lineCount, stringLength, renderWrapWidth;

- (CTFrameRef)frame
{
    if (*frameCache && frame == *frameCache)
        return *frameCache;
    
    // Release old cache
    if (*frameCache)
        CFRelease(*frameCache);
    
    // Create path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, (CGRect){ CGPointZero, { renderWrapWidth, CGFLOAT_MAX } });
    
    // Create frame
    frame = CTFramesetterCreateFrame(framesetter, (CFRange){ 0, 0 }, path, NULL);
    CGPathRelease(path);
    
    // Update cache and return
    *frameCache = frame;
    return frame;
}

- (void)setRenderWrapWidth:(CGFloat)width
{
    if (renderWrapWidth != width) 
    {
        renderWrapWidth = width;
        frame = NULL;
    }
}

- (CGFloat)renderHeight
{
    // Get height cache entry to update
    int cacheIdx = 0;
    for (int i = 0; i < HEIGHT_CACHE_SIZE; ++i) 
    {
        if (heightCache[i].wrapWidth == renderWrapWidth)
        {
            return heightCache[i].height;
        }
        else if (heightCache[i].wrapWidth == 0)
        {
            cacheIdx = i;
        }
    }
    
    // Calculate actual height
    heightCache[cacheIdx].wrapWidth = renderWrapWidth;
    heightCache[cacheIdx].height = 0;
    CFArrayRef lines = CTFrameGetLines(self.frame);
    CFIndex count = CFArrayGetCount(lines);
    CTLineRef line;
    CGFloat ascent, descent, leading;
    for (CFIndex i = 0; i < count; ++i)
    {
        line = CFArrayGetValueAtIndex(lines, i);
        CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        heightCache[cacheIdx].height += ascent + descent + leading;
    }
    
    return heightCache[cacheIdx].height;
}

- (BOOL)requireGeneration
{
    return framesetter == NULL;
}

#pragma mark TextSegment Methods

- (id)initWithFrameCache:(CTFrameRef *)cache
{
    if ((self = [super init])) 
    {
        frameCache = cache;
    }
    return self;
}

- (void)dealloc
{
    [self removeFramesetter];
    [super dealloc];
}

- (void)removeFramesetter
{
    if (framesetter)
    {
        CFRelease(framesetter);
        framesetter = NULL;
    }
    frame = NULL;
}

- (void)generateWithString:(NSAttributedString *)string havingLineCount:(NSUInteger)count
{
    [self removeFramesetter];
    framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    stringLength = [string length];
    lineCount = count;
    frame = NULL;
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void (^)(CTLineRef, CGRect, CGFloat, BOOL *))block 
                               reverse:(BOOL)reverse
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    BOOL stop = NO;
    CGFloat currentY = 0;
    CFArrayRef lines = CTFrameGetLines(self.frame);
    CFIndex count = CFArrayGetCount(lines);
    CGFloat width, ascent, descent, leading;
    CGRect bounds;
    // TODO!!! do reverse mode
    for (CFIndex i = 0; i < count; ++i) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        bounds = CGRectMake(0, currentY, width, ascent + descent + leading);
        if (currentY + bounds.size.height > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            //
            block(line, bounds, ascent, &stop);
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
    CTFrameRef globalFrame;
    
    NSMutableArray *textSegments;
    TextSegment *lastTextSegment;
    
    BOOL delegateHasTextRendererDidChangeRenderForTextWithinRectToRect;
    BOOL datasourceHasTextRendererEstimatedTextLineCountOfLength;
}

- (void)generateIfNeededTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range;

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
    if (globalFrame) 
    {
        CFRelease(globalFrame);
    }
    [super dealloc];
}

#pragma mark Private Methods

- (void)generateIfNeededTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range
{
    if (!segment.requireGeneration)
        return;
    
    NSUInteger originalRangeLength = range.length;
    NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&range];
    if (!string || range.length == 0 || [string length] == 0)
        return; // TODO throw?
    
    [segment generateWithString:string havingLineCount:range.length];
    
    // TODO receive message from delegate instead?
    if (range.length != originalRangeLength)
        lastTextSegment = segment;
}

#pragma mark Public Methods

- (void)invalidateAllText
{
    [textSegments removeAllObjects];
    lastTextSegment = nil;
    
    if (!lazyCaching) 
    {
        TextSegment *segment = nil;
        NSRange currentLineRange = NSMakeRange(0, preferredLineCountPerSegment);
        NSUInteger stringLocation = 0;
        NSAttributedString *string;
        while ((string = [datasource textRenderer:self stringInLineRange:&currentLineRange])) 
        {
            segment = [[TextSegment alloc] initWithFrameCache:&globalFrame];
            segment.renderWrapWidth = wrapWidth;
            [segment generateWithString:string havingLineCount:currentLineRange.length];
            
            [textSegments addObject:segment];
            [segment release];
            
            currentLineRange.location += currentLineRange.length;
            stringLocation += [string length];
        }
        lastTextSegment = segment;
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
            // and remember to set proper lastTextSegment
            if (lazyCaching) 
            {
                [segment removeFramesetter];
            }
            else
            {
                [self generateIfNeededTextSegment:segment withTextLineRange:segmentRange];
            }
        }
        
        currentLineLocation += segmentRange.length;
    }
}

- (void)clearCache
{
    for (TextSegment *segment in textSegments) 
    {
        [segment removeFramesetter];
    }
    
    if (globalFrame) 
    {
        CFRelease(globalFrame);
        globalFrame = NULL;
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
        [self generateIfNeededTextSegment:segment withTextLineRange:currentLineRange];
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
        
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(CTLineRef line, CGRect lineBound, CGFloat baseline, BOOL *stop) {
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
        } reverse:NO];
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
                    CGFloat width, ascent, descent, leading;
                    width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
                    meanLineHeight = ascent + descent + leading;
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

// TODO keep a single frame cached for all segment. if needed by this function
// use it. keep alway and only the last used frame. if the cached one is in the
// middle of the requested rect, draw backward.
- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context
{
    // Sanitize input
    if (!context)
        return;
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    // Setup rendering transformations
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextPosition(context, 0, 0);
    CGContextScaleCTM(context, 1, -1);
    
    // Enumerate used text segments
    TextSegment *segment = nil;
    NSUInteger currentSegmentIndex = 0;
    CGFloat lastSegmentEnd = 0, currentRectEnd;
    CGRect currentRect = rect;
    NSRange currentLineRange = NSMakeRange(0, 0);
    while (lastSegmentEnd < rectEnd)
    {
        // Exit if reached the last segment
        if (lastTextSegment && lastTextSegment == segment)
            return;
        
        // Generate segment if needed
        if ([textSegments count] <= currentSegmentIndex) 
        {
            segment = [[TextSegment alloc] initWithFrameCache:&globalFrame];
            segment.renderWrapWidth = wrapWidth;
            currentLineRange.length = preferredLineCountPerSegment;
            
            [textSegments addObject:segment];
            [segment release];
        }
        else
        {
            segment = [textSegments objectAtIndex:currentSegmentIndex];
            currentLineRange.length = segment.lineCount;
        }
        [self generateIfNeededTextSegment:segment withTextLineRange:currentLineRange];
        currentLineRange.length = segment.lineCount;
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
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(CTLineRef line, CGRect lineBound, CGFloat baseline, BOOL *stop) {
            // Require adjustment in rendering for first partial line
            if (lineBound.origin.y < currentRect.origin.y) 
            {
                CGContextTranslateCTM(context, 0, currentRect.origin.y - lineBound.origin.y);
            }
            // Positioning and rendering
            CGContextTranslateCTM(context, 0, -baseline);
            CTLineDraw(line, context);
            CGContextTranslateCTM(context, -lineBound.size.width, -lineBound.size.height+baseline);
        } reverse:NO];
        
        // Next segment
        currentSegmentIndex++;
    }
}

@end
