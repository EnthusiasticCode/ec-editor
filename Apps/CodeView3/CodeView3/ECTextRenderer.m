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


@class TextSegment;

typedef struct {
    TextSegment *segment;
    CTFrameRef frame;
} FrameCache;

#pragma mark -
#pragma mark TextSegment

#define HEIGHT_CACHE_SIZE (3)

@interface TextSegment : NSObject {
@private
    // The framesetter for thi segment
    CTFramesetterRef framesetter;
    FrameCache *cache;
    
    // Cache of heights for wrap widths
    struct { CGFloat wrapWidth; CGFloat height; } heightCache[HEIGHT_CACHE_SIZE];
}

- (id)initWithFrameCache:(FrameCache *)cache;

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
/// line in this segment. It also recive an offset from the origin y of the bounds
/// at wich the baseline is positioned.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, CGFloat baselineOffset, BOOL *stop))block;

/// Enumerate all the lines in the text segment within the given segment-relative 
/// string range. The block will also receive the relative line string range.
- (void)enumerateLinesInStringRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

/// Release framesetters and frames to reduce space consumption. To release the frame
/// this method will actually clear the framse cache.
- (void)removeFramesetter;

@end

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize frame, lineCount, stringLength, renderWrapWidth;

- (CTFrameRef)frame
{
    if (cache->frame && cache->segment == self)
        return cache->frame;
    
    // Release old cache
    if (cache->frame)
        CFRelease(cache->frame);
    
    // Create path
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, (CGRect){ CGPointZero, { renderWrapWidth, CGFLOAT_MAX } });
    
    // Create frame
    frame = CTFramesetterCreateFrame(framesetter, (CFRange){ 0, 0 }, path, NULL);
    CGPathRelease(path);
    
    // Update cache and return
    cache->segment = self;
    cache->frame = frame;
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

- (id)initWithFrameCache:(FrameCache *)aCache
{
    if ((self = [super init])) 
    {
        cache = aCache;
    }
    return self;
}

- (void)dealloc
{
    if (cache->segment == self)
        cache->segment = nil;
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

// TODO!!! do reverse mode
- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void (^)(CTLineRef, CGRect, CGFloat, BOOL *))block 
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    BOOL stop = NO;
    CFArrayRef lines = CTFrameGetLines(self.frame);
    CFIndex count = CFArrayGetCount(lines);
    
    CGFloat currentY = 0;
    CGFloat width, ascent, descent, leading;
    CGRect bounds;
    
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

- (void)enumerateLinesInStringRange:(NSRange)queryRange usingBlock:(void (^)(CTLineRef, CGRect, NSRange, BOOL *))block
{
    NSUInteger queryRangeEnd = queryRange.location + queryRange.length;
    
    BOOL stop = NO;
    CFArrayRef lines = CTFrameGetLines(self.frame);
    CFIndex count = CFArrayGetCount(lines);
    
    CGFloat currentY = 0;
    CGFloat width, ascent, descent, leading;
    CGRect bounds;
    
    CFRange stringRange;
    
    for (CFIndex i = 0; i < count; ++i)
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        stringRange = CTLineGetStringRange(line);
        if (stringRange.location >= queryRangeEnd)
            return;
        
        width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        bounds = CGRectMake(0, currentY, width, ascent + descent + leading);
        
        if (stringRange.location + stringRange.length > queryRange.location) 
        {
            block(line, bounds, (NSRange){ stringRange.location, stringRange.length }, &stop);
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
    FrameCache globalCache;
    
    NSMutableArray *textSegments;
    TextSegment *lastTextSegment;
    
    BOOL delegateHasTextRendererInvalidateRenderInRect;
    BOOL datasourceHasTextRendererEstimatedTextLineCountOfLength;
}

/// Generate a segment with the given line range if not already generated.
/// Return YES if segment is usable or NO if it should not be used and removed
/// from the segment array.
- (BOOL)generateIfNeededTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range;

- (void)generateTextSegmentsAndEnumerateUsingBlock:(void(^)(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop))block;

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, CGFloat baselineOffset, BOOL *stop))block;

@end


@implementation ECTextRenderer

#pragma mark Properties

@synthesize delegate, datasource, preferredLineCountPerSegment, lazyCaching, wrapWidth, estimatedHeight;

- (void)setDelegate:(id<ECTextRendererDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasTextRendererInvalidateRenderInRect = [delegate respondsToSelector:@selector(textRenderer:invalidateRenderInRect:)];
}

- (void)setDatasource:(id<ECTextRendererDataSource>)aDatasource
{
    datasource = aDatasource;
    datasourceHasTextRendererEstimatedTextLineCountOfLength = [datasource respondsToSelector:@selector(textRenderer:estimatedTextLineCountOfLength:)];
    
    [self updateAllText];
}

- (void)setWrapWidth:(CGFloat)width
{
    if (wrapWidth != width) 
    {
        wrapWidth = width;
        for (TextSegment *segment in textSegments) 
        {
            segment.renderWrapWidth = width;
        }
        estimatedHeight = 0;
    }
}

- (CGFloat)estimatedHeight
{
    if (estimatedHeight == 0) 
    {
        estimatedHeight = [self rectForIntegralNumberOfTextLinesWithinRect:CGRectInfinite allowGuessedResult:YES].size.height;
    }
    
    return estimatedHeight;
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
    if (globalCache.frame) 
    {
        CFRelease(globalCache.frame);
    }
    [super dealloc];
}

#pragma mark Private Methods

- (BOOL)generateIfNeededTextSegment:(TextSegment *)segment withTextLineRange:(NSRange)range
{
    if (!segment.requireGeneration)
        return YES;
    
    NSUInteger originalRangeLength = range.length;
    NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&range];
    if (!string || range.length == 0 || [string length] == 0)
    {
        return NO;
    }
    
    [segment generateWithString:string havingLineCount:range.length];
    
    // TODO receive message from delegate instead?
    if (range.length != originalRangeLength)
        lastTextSegment = segment;
    
    return YES;
}

- (void)generateTextSegmentsAndEnumerateUsingBlock:(void (^)(TextSegment *, NSUInteger, NSUInteger, NSUInteger, CGFloat, BOOL *))block
{
    BOOL stop = NO;
    TextSegment *segment = nil;
    NSUInteger currentIndex = 0;
    NSRange currentLineRange = NSMakeRange(0, 0);
    NSUInteger currentStringOffset = 0;
    CGFloat currentPositionOffset = 0;
    do
    {
        if (lastTextSegment && lastTextSegment == segment)
            break;
        
        // Generate segment if needed
        if ([textSegments count] <= currentIndex) 
        {
            segment = [[TextSegment alloc] initWithFrameCache:&globalCache];
            segment.renderWrapWidth = wrapWidth;
            currentLineRange.length = preferredLineCountPerSegment;
            
            [textSegments addObject:segment];
            [segment release];
        }
        else
        {
            segment = [textSegments objectAtIndex:currentIndex];
            currentLineRange.length = segment.lineCount;
        }
        
        // Generate segment if needed and remove it if invalid
        if (![self generateIfNeededTextSegment:segment withTextLineRange:currentLineRange])
        {
            [textSegments removeObject:segment];
            lastTextSegment = [textSegments lastObject];
            break;
        }
        
        // Apply block
        block(segment, currentIndex, currentLineRange.location, currentStringOffset, currentPositionOffset, &stop);
        
        // Update offsets
        currentIndex++;
        currentLineRange.length = segment.lineCount;
        currentLineRange.location += currentLineRange.length;
        currentStringOffset += segment.stringLength;
        currentPositionOffset += segment.renderHeight;
        
    } while (!stop);
    
    // Update estimated height
    if (currentPositionOffset > estimatedHeight 
        || (lastTextSegment == segment && currentPositionOffset != estimatedHeight)) 
    {
        [self willChangeValueForKey:@"estimatedHeight"];
        estimatedHeight = currentPositionOffset;
        [self didChangeValueForKey:@"estimatedHeight"];
    }
}

#pragma mark Public Outtake Methods

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(CTLineRef, CGRect, CGFloat, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
        // End when past rect
        if (positionOffset > rectEnd)
        {
            *stop = YES;
            return;
        }
        
        // Skip not intersected segments
        if (rect.origin.y > positionOffset + segment.renderHeight)
            return;
        
        // Adjust rect to current segment relative coordinates
        CGRect currentRect = rect;
        currentRect.origin.y -= positionOffset;
//        if (currentRect.origin.y < 0)
//        {
//            currentRect.size.height += currentRect.origin.y;
//            currentRect.origin.y = 0;
//        }
//        if (CGRectGetMaxY(currentRect) <= 0)
//        {
//            *stop = YES;
//            return;
//        }
        
        // Enumerate needed lines from this segment
        __block CGFloat lastLineEnd = rect.origin.y;
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(CTLineRef line, CGRect lineBound, CGFloat baselineOffset, BOOL *stopInner) {
            lineBound.origin.y += positionOffset;
            lastLineEnd += lineBound.size.height;
            block(line, lineBound, baselineOffset, stopInner);
            *stop = *stopInner;
        }];
        
        // Stop if last line esceed the input rect
        if (lastLineEnd >= rectEnd)
            *stop = YES;
    }];
}

// TODO keep a single frame cached for all segment. if needed by this function
// use it. keep alway and only the last used frame. if the cached one is in the
// middle of the requested rect, draw backward.
- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context
{
    // Sanitize input
    if (!context)
        return;
    
    // Setup rendering transformations
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSetTextPosition(context, 0, 0);
    CGContextScaleCTM(context, 1, -1);
    
    // Draw needed lines from this segment
    [self enumerateLinesIntersectingRect:rect usingBlock:^(CTLineRef line, CGRect lineBound, CGFloat baseline, BOOL *stop) {
        // Require adjustment in rendering for first partial line
        if (lineBound.origin.y < rect.origin.y) 
        {
            CGContextTranslateCTM(context, 0, rect.origin.y - lineBound.origin.y);
        }
        // Positioning and rendering
        CGContextTranslateCTM(context, 0, -baseline);
        CTLineDraw(line, context);
        CGContextTranslateCTM(context, -lineBound.size.width, -lineBound.size.height+baseline);
    }];
}

- (NSUInteger)closestPositionToPoint:(CGPoint)point withinStringRange:(NSRange)queryStringRange
{
    __block NSUInteger result = 0;
    __block CTLineRef lastLine = NULL;
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
        // Skip segment if before required string range
        if (stringOffset + segment.stringLength <= queryStringRange.location)
            return;
        
        // Get relative positions to current semgnet
        CGPoint segmentRelativePoint = point;
        segmentRelativePoint.y -= positionOffset;
        NSRange segmentRelativeStringRange = queryStringRange;
        segmentRelativeStringRange.location -= stringOffset;
        
        [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, CGRect lineBounds, NSRange lineStringRange, BOOL *innerStop) {
            lastLine = line;
            
            // Skip lines before point
            if (segmentRelativePoint.y >= lineBounds.origin.y + lineBounds.size.height)
                return;
            
            result = CTLineGetStringIndexForPosition(line, segmentRelativePoint);
            *stop = *innerStop = YES;
        }];
        
        // Prepare result
        if (*stop)
            result += stringOffset;
    }];
    // TODO!!! use lastline to compute result in case of 0
    return result;
}

- (CGRect)boundsOfLinesForStringRange:(NSRange)queryStringRange
{
    __block CGRect result = CGRectNull;
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
        // Skip segment if before required string range
        if (stringOffset + segment.stringLength <= queryStringRange.location)
            return;
        
        // Get relative positions to current semgnet
        __block NSRange segmentRelativeStringRange = queryStringRange;
        segmentRelativeStringRange.location -= stringOffset;
        
        [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, CGRect lineBounds, NSRange lineStringRange, BOOL *stop) {
            lineBounds.origin.y += positionOffset;
            result = CGRectUnion(result, lineBounds);
            
            segmentRelativeStringRange.location += lineStringRange.length;
        }];
        
        // Exit if finished
        if (segmentRelativeStringRange.location + stringOffset >= queryStringRange.location + queryStringRange.length)
            *stop = YES;
    }];
    return result;
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
    // TODO this should be more like the draw function for non guessed requests
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

#pragma mark Public Intake Methods

- (void)updateAllText
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
            segment = [[TextSegment alloc] initWithFrameCache:&globalCache];
            segment.renderWrapWidth = wrapWidth;
            [segment generateWithString:string havingLineCount:currentLineRange.length];
            
            [textSegments addObject:segment];
            [segment release];
            
            currentLineRange.location += currentLineRange.length;
            stringLocation += [string length];
        }
        lastTextSegment = segment;
    }
    
    if (delegateHasTextRendererInvalidateRenderInRect) 
    {
        CGRect changedRect = CGRectMake(0, 0, wrapWidth, estimatedHeight);
        [delegate textRenderer:self invalidateRenderInRect:changedRect];
    }
    
    // TODO inform kvo?
    estimatedHeight = 0;
}

- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange
{
    CGFloat currentY = 0;
    CGRect changedRect = CGRectNull, currentRect;
    
    NSUInteger currentLineLocation = 0;
    NSRange segmentRange, origInsersect, newIntersec;
    for (TextSegment *segment in textSegments) 
    {
        segmentRange = (NSRange){ currentLineLocation, segment.lineCount };
        
        origInsersect = NSIntersectionRange(originalRange, segmentRange);
        if (origInsersect.length > 0)
        {
            // Compute change intersection
            newIntersec = NSIntersectionRange(newRange, segmentRange);
            segmentRange.length += (newIntersec.length - origInsersect.length);
            segment.lineCount = segmentRange.length;
            
            // Update dirty rect
            currentRect = CGRectMake(0, currentY, wrapWidth, segment.renderHeight);
            changedRect = CGRectUnion(changedRect, currentRect);
            currentY += currentRect.size.height;
            
            // TODO!!! if lineCount > 1.5 * preferred -> split or merge if * 0.5
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
    
    if (delegateHasTextRendererInvalidateRenderInRect) 
    {
        [delegate textRenderer:self invalidateRenderInRect:changedRect];
    }
    
    // TODO inform kvo?
    estimatedHeight = 0;
}

- (void)clearCache
{
    for (TextSegment *segment in textSegments) 
    {
        [segment removeFramesetter];
    }
    
    globalCache.segment = nil;
    if (globalCache.frame) 
    {
        CFRelease(globalCache.frame);
        globalCache.frame = NULL;
    }
}

@end
