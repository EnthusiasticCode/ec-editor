//
//  ECTextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRenderer.h"
#import <CoreText/CoreText.h>
#import "ECTextStyle.h"
#import "ECDictionaryCache.h"

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
@class TextSegmentFrame;

#pragma mark - ECTextRenderer Interface (Class extension)

@interface ECTextRenderer () {
@private
    NSMutableArray *textSegments;
    TextSegment *lastTextSegment;
    
    BOOL delegateHasTextRendererInvalidateRenderInRect;
    BOOL datasourceHasTextRendererEstimatedTextLineCountOfLength;
}

#warning TODO use NSCache?
/// Text renderer typesetters' cache shared among all text segments.
@property (nonatomic, readonly, strong) ECDictionaryCache *typesettersCache;

/// Text renderer line arrays' cache shared among all text segments.
@property (nonatomic, readonly, strong) ECDictionaryCache *renderedLinesCache;

/// Retrieve the string for the given text segment. Line count is an output parameter, pass NULL if not interested.
/// This function is supposed to be used by a text segment to generate it's typesetter if not present in cache.
/// The function can return NULL if the source string has no text for the given segment.
- (NSAttributedString *)stringForTextSegment:(TextSegment *)segment lineCount:(NSUInteger *)lines;

/// Enumerate throught text segments creating them if not yet present. This function
/// guarantee to enumerate throught all the text segments that cover the entire
/// source text.
- (void)generateTextSegmentsAndEnumerateUsingBlock:(void(^)(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop))block;

/// Convenience function to enumerate throught all lines (indipendent from text segment)
/// contained in the given rect relative to the rendered text space.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, CGFloat baselineOffset, BOOL *stop))block;

@end

#pragma mark - RenderedLine Interface

/// A class to wrap a core text line and add extra informations.
@interface RenderedLine : NSObject {
@public
    CTLineRef CTLine;
    CGFloat width;
    CGFloat ascent;
    CGFloat descent;
    BOOL hasNewLine;
}

/// The rendered core text line.
@property (nonatomic) CTLineRef CTLine;

@property (nonatomic) CGFloat width;

@property (nonatomic) CGFloat ascent;

@property (nonatomic) CGFloat descent;

@property (nonatomic, readonly) CGFloat height;

/// Indicates if the line text has a new line meaning that it will advance the 
/// actual text line count.
@property (nonatomic) BOOL hasNewLine;

+ (id)renderedLineWithCTLine:(CTLineRef)line hasNewLine:(BOOL)newLine;

@end

#pragma mark - TextSegment Interface

#define HEIGHT_CACHE_SIZE (3)

/// A Text Segment represent a part of the text rendered. The segment represented
/// text is limited by the number of lines in \c preferredLineCountPerSegment.
@interface TextSegment : NSObject {
@private
    ECTextRenderer *parentRenderer;
    
    /// Cache of heights for wrap widths
    struct { CGFloat wrapWidth; CGFloat height; } heightCache[HEIGHT_CACHE_SIZE];
}

- (id)initWithTextRenderer:(ECTextRenderer *)renderer;

/// The string rendered with this text segment.
@property (nonatomic, readonly, weak) NSAttributedString *string;

/// The length of the receiver's string. Use this method instead of [string length]
/// to avoid calling on a deallocated cache.
@property (nonatomic) NSUInteger stringLength;

/// The typesetter generated from the text segment string.
@property (nonatomic, readonly) CTTypesetterRef typesetter;

/// An array of rendered wrapped lines ready to be drawn on a context.
@property (nonatomic, readonly, weak) NSArray *renderedLines;

/// Count of string lines used to generate the segment's framesetter.
@property (nonatomic) NSUInteger lineCount;

/// Indicates if the text segment is valid.
@property (nonatomic, readonly, getter = isValid) BOOL valid;

/// The current render width. Changing this property will make the segment to
/// generate a new frame if no one with this width is present in cache.
@property (nonatomic) CGFloat renderWrapWidth;

/// The actual render height of the whole string in the segment at the current
/// wrap width.
@property (nonatomic, readonly) CGFloat renderHeight;

/// Enumerate all the rendered lines in the text segment that intersect the given rect. 
/// The rect should be relative to this segment coordinates.
/// The block to apply will receive the line and its bounds relative to the first rendered
/// line in this segment. It also recive an offset from the origin y of the bounds
/// at wich the baseline is positioned.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBound, CGFloat baselineOffset, BOOL *stop))block;

/// Enumerate all the lines in the text segment within the given segment-relative 
/// string range. The block will also receive the relative line string range.
- (void)enumerateLinesInStringRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

- (void)enumerateLinesInLineRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

@end


#pragma mark - Implementations

#pragma mark - RenderedLine Implementation

@implementation RenderedLine

@synthesize CTLine, width, ascent, descent, hasNewLine;

- (CGFloat)height
{
    return ascent + descent;
}

- (void)dealloc
{
    if (CTLine)
        CFRelease(CTLine);
//    NSLog(@"dealloc - this sould not happen!");
}

+ (RenderedLine *)renderedLineWithCTLine:(CTLineRef)line hasNewLine:(BOOL)newLine
{
    ECASSERT(line != NULL);
    
    RenderedLine *result = [RenderedLine new];
    result->CTLine = CFRetain(line);
    result->width = CTLineGetTypographicBounds(line, &result->ascent, &result->descent, NULL);
    result->hasNewLine = newLine;
    return result;
}

@end


#pragma mark - TextSegment Implementation

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize lineCount, renderWrapWidth, string, stringLength, valid;

- (CTTypesetterRef)typesetter
{
    CTTypesetterRef t = (__bridge CTTypesetterRef)[parentRenderer.typesettersCache objectForKey:self];
    
    if (!t)
    {
        string = [parentRenderer stringForTextSegment:self lineCount:&lineCount];
        if (!string)
            return NULL;
        
        stringLength = [string length];
        t = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)string);
        
        // Cache
        if (t) 
        {
            [parentRenderer.typesettersCache setObject:(__bridge id)t forKey:self];
            CFRelease(t);
        }

        // Remove frame
        [parentRenderer.renderedLinesCache removeObjectForKey:self];
    }
    
    return t;
}

- (NSArray *)renderedLines
{
    NSMutableArray *lines = [parentRenderer.renderedLinesCache objectForKey:self];
    
    if (!lines)
    {
        // Retrieve typesetter and string
        CTTypesetterRef typesetter = self.typesetter;
        lines = [[NSMutableArray alloc] initWithCapacity:lineCount];
        
        // Generate wrapped lines
        __block CFRange lineRange = CFRangeMake(0, 0);
        [string.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            CFIndex lineLength = [line length], truncationLenght;
            do {
                // TODO possibly filter using customizable block
                truncationLenght = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, renderWrapWidth);
                
                // Generate line
                lineRange.length = truncationLenght;
                CTLineRef ctline = CTTypesetterCreateLine(typesetter, lineRange);
                lineRange.location += lineRange.length;
                
                // Save line
                [lines addObject:[RenderedLine renderedLineWithCTLine:ctline hasNewLine:(lineLength <= truncationLenght)]];
                lineLength -= truncationLenght;
                CFRelease(ctline);
            } while (lineLength > 0);
        }];
        
        // Cache result
        [parentRenderer.renderedLinesCache setObject:lines forKey:self];
    }
    return lines;
}

- (void)setRenderWrapWidth:(CGFloat)width
{
    if (renderWrapWidth != width) 
    {
        renderWrapWidth = width;
        [parentRenderer.renderedLinesCache removeObjectForKey:self];
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
    for (RenderedLine *line in self.renderedLines)
    {
        heightCache[cacheIdx].height += line->ascent + line->descent;
    }
    
    return heightCache[cacheIdx].height;
}

#pragma mark TextSegment Methods

- (id)initWithTextRenderer:(ECTextRenderer *)renderer
{
    ECASSERT(renderer != nil);
    
    if ((self = [super init])) 
    {
        parentRenderer = renderer;
        valid = self.typesetter != NULL;
    }
    return self;
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect 
                            usingBlock:(void (^)(CTLineRef, CGRect, CGFloat, BOOL *))block 
{
    ECASSERT(valid);
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    CGFloat currentY = 0;
    CGRect bounds;
    
#warning TODO fix for in!!!
    BOOL stop = NO;
    NSArray *lines = self.renderedLines;
    for (NSUInteger i = 0; i < [lines count]; ++i)
    {
        RenderedLine *line = [lines objectAtIndex:i];
        
        bounds = CGRectMake(0, currentY, line->width, line->ascent + line->descent);
        if (currentY + bounds.size.height > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            //
            block(line->CTLine, bounds, line->ascent, &stop);
            if (stop) break;
        }
        currentY += bounds.size.height;
    }
}

- (void)enumerateLinesInStringRange:(NSRange)queryRange usingBlock:(void (^)(CTLineRef, NSUInteger, CGRect, NSRange, BOOL *))block
{
    ECASSERT(valid);
    
    NSUInteger queryRangeEnd = NSUIntegerMax;
    if (queryRange.length > 0)
        queryRangeEnd = queryRange.location + queryRange.length;
    
    CGFloat currentY = 0;
    CGRect bounds;
    CFRange stringRange;
    NSUInteger lineIndex = 0;
    
    BOOL stop = NO;
    for (RenderedLine *line in self.renderedLines)
    {
        stringRange = CTLineGetStringRange(line->CTLine);
        if ((NSUInteger)stringRange.location >= queryRangeEnd)
            return;
        
        bounds = CGRectMake(0, currentY, line->width, line->ascent + line->descent);
        
        if ((NSUInteger)(stringRange.location + stringRange.length) > queryRange.location) 
        {
            block(line->CTLine, lineIndex, bounds, (NSRange){ stringRange.location, stringRange.length }, &stop);
            if (stop) break;
        }

        currentY += bounds.size.height;
        lineIndex++;
    }
}

- (void)enumerateLinesInLineRange:(NSRange)queryRange 
                       usingBlock:(void (^)(CTLineRef, NSUInteger, CGRect, NSRange, BOOL *))block
{
    ECASSERT(valid);
    
    NSUInteger queryRangeEnd = NSUIntegerMax;
    if (queryRange.length > 0)
        queryRangeEnd = queryRange.location + queryRange.length;
    
    CGFloat currentY = 0;
    CGRect bounds;
    CFRange stringRange;
    NSUInteger lineIndex = 0;
    
    BOOL stop = NO;
    for (RenderedLine *line in self.renderedLines)
    {
        if (lineIndex >= (CFIndex)queryRangeEnd) 
            return;
            
        stringRange = CTLineGetStringRange(line->CTLine);
        
        bounds = CGRectMake(0, currentY, line->width, line->ascent + line->descent);
        
        if ((NSUInteger)(stringRange.location + stringRange.length) > queryRange.location) 
        {
            block(line->CTLine, lineIndex, bounds, (NSRange){ stringRange.location, stringRange.length }, &stop);
            if (stop) break;
        }
        
        currentY += bounds.size.height;
        lineIndex++;
    }
}

@end

#pragma mark -
#pragma mark ECTextRenderer Implementation


@implementation ECTextRenderer

#pragma mark Properties

@synthesize typesettersCache, renderedLinesCache;
@synthesize delegate, datasource, preferredLineCountPerSegment, wrapWidth, estimatedHeight;

- (void)setDelegate:(id<ECTextRendererDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasTextRendererInvalidateRenderInRect = [delegate respondsToSelector:@selector(textRenderer:invalidateRenderInRect:)];
}

- (void)setDatasource:(id<ECTextRendererDataSource>)aDatasource
{
    if (datasource == aDatasource)
        return;
    
    datasource = aDatasource;
    datasourceHasTextRendererEstimatedTextLineCountOfLength = [datasource respondsToSelector:@selector(textRenderer:estimatedTextLineCountOfLength:)];
    
    [self updateAllText];
}

- (void)setWrapWidth:(CGFloat)width
{
    if (wrapWidth == width) 
        return;

    [renderedLinesCache removeAllObjects];
    wrapWidth = width;
    for (TextSegment *segment in textSegments) 
    {
        segment.renderWrapWidth = width;
    }
    estimatedHeight = 0;
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
        textSegments = [NSMutableArray new];
//#warning TODO check if count limit works as expected
//        typesettersCache = [NSCache new];
//        typesettersCache.countLimit = 5;
//        renderedLinesCache = [NSCache new];
//        renderedLinesCache.countLimit = 3;
        typesettersCache = [[ECDictionaryCache alloc] initWithCountLimit:5];
        renderedLinesCache = [[ECDictionaryCache alloc] initWithCountLimit:2];
    }
    return self;
}

#pragma mark Private Methods

- (NSAttributedString *)stringForTextSegment:(TextSegment *)requestSegment lineCount:(NSUInteger *)lines
{
    NSRange lineRange = NSMakeRange(0, 0);
    
    // Source text line offset for requested segment
    for (TextSegment *segment in textSegments) 
    {
        if (segment == requestSegment)
            break;
        lineRange.location += segment.lineCount;
    }
    
    // Source text string for requested segment
    BOOL endOfString = NO;
    lineRange.length = requestSegment.lineCount ? requestSegment.lineCount : preferredLineCountPerSegment;
    NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&lineRange endOfString:&endOfString];
    if (!string || lineRange.length == 0 || [string length] == 0)
        return NULL;
    
    if (endOfString)
        lastTextSegment = requestSegment;
    
    if (lines)
        *lines = lineRange.length;
    
    return string;
}

- (void)generateTextSegmentsAndEnumerateUsingBlock:(void (^)(TextSegment *, NSUInteger, NSUInteger, NSUInteger, CGFloat, BOOL *))block
{
    BOOL stop = NO;
    TextSegment *segment = nil;
    NSUInteger currentIndex = 0;
    NSRange currentLineRange = NSMakeRange(0, 0);
    NSUInteger currentStringOffset = 0;
    CGFloat currentPositionOffset = 0;
    // TODO add @synchronized (textSegments)?
    do
    {
        if (lastTextSegment && lastTextSegment == segment)
            break;
        
        // Generate segment if needed
        if ([textSegments count] <= currentIndex) 
        {
            segment = [[TextSegment alloc] initWithTextRenderer:self];
            segment.renderWrapWidth = wrapWidth;
            if (!segment.isValid) 
            {
                lastTextSegment = [textSegments lastObject];
                break;
            }
            
            [textSegments addObject:segment];
        }
        else
        {
            segment = [textSegments objectAtIndex:currentIndex];
        }
        currentLineRange.length = segment.lineCount;
        
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

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(CTLineRef, CGRect, CGFloat, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
        rect = CGRectInfinite;
    
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

#pragma mark Public Outtake Methods

- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context
{
    ECASSERT(context != NULL);
    
    CGContextRetain(context);
    
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

        CGRect runRect = lineBound;
        runRect.origin.y = - lineBound.size.height + baseline;
        CGFloat runWidth;
        
        CFArrayRef runs = CTLineGetGlyphRuns(line);
        CFIndex runCount = CFArrayGetCount(runs);
        CTRunRef run;
        
        NSDictionary *runAttributes;
        ECTextStyleCustomOverlayBlock block;
        for (CFIndex i = 0; i < runCount; ++i) 
        {
            run = CFArrayGetValueAtIndex(runs, i);
            
            // Get run width
            runWidth = CTRunGetTypographicBounds(run, (CFRange){0, 0}, NULL, NULL, NULL);
            runRect.size.width = runWidth;
            
            // Get run attributes but not for last run in line (new line character)
            if (i == runCount - 1) 
                runAttributes = nil;
            else
                runAttributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
            
            // Apply custom back attributes
            if (runAttributes)
            {
                CGColorRef backgroundColor = (__bridge CGColorRef)[runAttributes objectForKey:ECTSBackgroundColorAttributeName];
                if (backgroundColor) 
                {
                    CGContextSetFillColorWithColor(context, backgroundColor);
                    CGContextFillRect(context, runRect);
                }
                block = [runAttributes objectForKey:ECTSBackCustomOverlayAttributeName];
                if (block) 
                {
                    CGContextSaveGState(context);
                    block(context, runRect);
                    CGContextRestoreGState(context);
                }
            }
            
            // Draw run
            CTRunDraw(run, context, (CFRange){ 0, 0 });
            
            // Apply custom front attributes
            if (runAttributes && (block = [runAttributes objectForKey:ECTSFrontCustomOverlayAttributeName])) 
            {
                CGContextSaveGState(context);
                block(context, runRect);
                CGContextRestoreGState(context);
            }
            
            // Advance run origin
            runRect.origin.x += runWidth;
        }

        CGContextTranslateCTM(context, 0, -lineBound.size.height+baseline);
    }];
    
    CGContextRelease(context);
}

- (NSUInteger)closestStringLocationToPoint:(CGPoint)point withinStringRange:(NSRange)queryStringRange
{
    __block CFIndex result = 0;
    __block CTLineRef lastLine = NULL;
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
        NSUInteger segmentStringLength = segment.stringLength;
        
        // Skip segment if before required string range
        if (stringOffset + segmentStringLength <= queryStringRange.location)
            return;
        
        // Get relative positions to current semgnet
        CGPoint segmentRelativePoint = point;
        segmentRelativePoint.y -= positionOffset;
        NSRange segmentRelativeStringRange = queryStringRange;
        if (queryStringRange.length > 0) 
            segmentRelativeStringRange = NSIntersectionRange(queryStringRange, (NSRange){ stringOffset, segmentStringLength });
        else if (queryStringRange.location >= stringOffset)
            segmentRelativeStringRange.location -= stringOffset;
        
        [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, NSUInteger innerIdx, CGRect lineBounds, NSRange lineStringRange, BOOL *innerStop) {
            lastLine = line;
            
            // Skip lines before point
            if (segmentRelativePoint.y >= lineBounds.origin.y + lineBounds.size.height)
                return;
            
            result = CTLineGetStringIndexForPosition(line, segmentRelativePoint);
            if (result == (CFIndex)(lineStringRange.location + lineStringRange.length))
                result--;
            *stop = *innerStop = YES;
        }];
        
        // Prepare result offset
        if (!*stop && lastLine)
        {
            result = CTLineGetStringIndexForPosition(lastLine, point);
            CFRange lastLineRange = CTLineGetStringRange(lastLine);
            if (result == lastLineRange.location + lastLineRange.length)
                result--;
        }
        result += stringOffset;
    }];
    return result;
}

- (ECRectSet *)rectsForStringRange:(NSRange)queryStringRange limitToFirstLine:(BOOL)limit
{
    ECMutableRectSet *result = [ECMutableRectSet rectSetWithCapacity:1];
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
        // Skip segment if before required string range
        if (stringOffset + segment.stringLength < queryStringRange.location)
            return;
        
        // Get relative positions to current semgnet
        NSRange segmentRelativeStringRange = queryStringRange;
        segmentRelativeStringRange.location -= stringOffset;
        NSUInteger segmentRelativeStringRangeEnd = segmentRelativeStringRange.location + segmentRelativeStringRange.length;
        
        __block NSUInteger stringEnd = stringOffset;
        [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, NSUInteger innerIdx, CGRect lineBounds, NSRange lineStringRange, BOOL *innserStop) {
            lineBounds.origin.y += positionOffset;
            
            // Query range start inside this line
            if (segmentRelativeStringRange.location > lineStringRange.location) 
            {
                CGFloat offset = CTLineGetOffsetForStringIndex(line, segmentRelativeStringRange.location, NULL);
                lineBounds.origin.x = offset;
                lineBounds.size.width -= offset;
            }
            
            // Query range end inside this line
            if (segmentRelativeStringRangeEnd <= lineStringRange.location + lineStringRange.length) 
            {
                CGFloat offset = CTLineGetOffsetForStringIndex(line, segmentRelativeStringRangeEnd, NULL);
                lineBounds.size.width = offset - lineBounds.origin.x;
            }
            
            [result addRect:lineBounds];
            
            stringEnd += lineStringRange.length;
            
            if (limit)
                *stop = *innserStop = YES;
        }];
        
        // Exit if finished
        if (stringEnd >= queryStringRange.location + queryStringRange.length)
            *stop = YES;
    }];
    return result;
}

- (NSUInteger)positionFromPosition:(NSUInteger)position inLayoutDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    if (offset == 0)
        return position;
    
    NSUInteger result = NSUIntegerMax;
    switch (direction) {
        case UITextLayoutDirectionUp:
            offset = -offset;
            
        case UITextLayoutDirectionDown:
        {
            // TODO extract this to a convinience method - lineIndexForPosition:
            __block CGFloat positionX = 0;
            __block NSUInteger positionLine = NSUIntegerMax;
            [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
                // Skip segment if before required string range
                if (stringOffset + segment.stringLength < position)
                    return;
                
                // Get relative positions to current semgnet
                NSRange segmentRelativeStringRange = NSMakeRange(position, 0);
                segmentRelativeStringRange.location -= stringOffset;
                
                // Retrieve start position line index
                [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, NSUInteger innerIdx, CGRect lineBounds, NSRange lineStringRange, BOOL *innserStop) {
                    positionLine = innerIdx;
                    
                    positionX = CTLineGetOffsetForStringIndex(line, (position - stringOffset), NULL);
                    positionX += lineBounds.origin.x;
                    
                    *stop = *innserStop = YES;
                }];
            }];
            // If offset will move outsite rendered text line range, return
            if (offset < 0 && -offset > (NSInteger)positionLine)
                break;
            // Look for new position
            NSUInteger requestLine = positionLine + offset;
            __block CFIndex requestPosition = kCFNotFound;
            [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
                // Skip segment if before required line
                if (lineOffset + segment.lineCount < requestLine)
                    return;
                
                // Get relative positions to current semgnet
                NSRange segmentRelativeLineRange = NSMakeRange(requestLine, 0);
                segmentRelativeLineRange.location -= lineOffset;
                
                // Retrieve start position line index
                [segment enumerateLinesInLineRange:segmentRelativeLineRange usingBlock:^(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stopInner) {
                    positionX -= lineBounds.origin.x;
                    if (positionX >= CGRectGetMaxX(lineBounds))
                        requestPosition = NSMaxRange(lineStringRange) - 1;
                    else
                        // TODO there may be problems summing cfindex to nsuinteger
                        requestPosition = CTLineGetStringIndexForPosition(line, (CGPoint){ positionX, 0 });
                    requestPosition += stringOffset;
                    *stop = *stopInner = YES;
                }];
            }];
            // Set result if present
            if (requestPosition != kCFNotFound)
                result = requestPosition;
            break;
        }
            
        case UITextLayoutDirectionLeft:
            offset = -offset;
            
        case UITextLayoutDirectionRight:
        {
            // If offset will move outsite rendered text line range, return
            if (offset < 0 && -offset > (NSInteger)position)
                break;
            
            // TODO may require moving visually with graphene clusters.
            result = position + offset;
            break;
        }

        default:
            break;
    }
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
//        if (guessed && [framesettersCache objectForKey:segment] == nil)
//            break;
        
        currentLineRange.length = segment.lineCount;
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
            maxCharsForLine = MAX((CFIndex)maxCharsForLine, CTLineGetGlyphCount(line));
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
                BOOL isStringEnd = NO;
                NSRange tempRange = NSMakeRange(0, 1);
                NSAttributedString *string = [datasource textRenderer:self stringInLineRange:&tempRange endOfString:&isStringEnd];
                if (string) 
                {
                    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)string);
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
    [self clearCache];
    [textSegments removeAllObjects];
    lastTextSegment = nil;
    
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
            [typesettersCache removeObjectForKey:segment];
            [renderedLinesCache removeObjectForKey:segment];
            // TODO!!! instead of cleaning the cache, use a segment method to update just those lines
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
    [typesettersCache removeAllObjects];
    [renderedLinesCache removeAllObjects];
}

@end
