//
//  ECTextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRenderer.h"
#import "ECTextStyle.h"

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
    
    struct {
        unsigned int delegateHasTextInsetsForTextRenderer : 1;
        unsigned int delegateHasTextRendererInvalidateRenderInRect : 1;
        unsigned int delegateHasUnderlayPassesForTextRenderer : 1;
        unsigned int delegateHasOverlayPassesForTextRenderer : 1;
        unsigned int dataSourceHasTextRendererEstimatedTextLineCountOfLength : 1;
        unsigned int reserved : 3;
    } flags;
}

/// Shourtcut to retrieve the text insets from the delegate.
@property (nonatomic, readonly) UIEdgeInsets textInsets;

/// Text renderer strings' cache shared among all text segments.
@property (nonatomic, readonly, strong) NSCache *segmentStringsCache;

/// Text renderer typesetters' cache shared among all text segments.
@property (nonatomic, readonly, strong) NSCache *typesettersCache;

/// Text renderer line arrays' cache shared among all text segments.
@property (nonatomic, readonly, strong) NSCache *renderedLinesCache;

/// Retrieve the string for the given text segment. Line count is an output parameter, pass NULL if not interested.
/// This function is supposed to be used by a text segment to generate it's typesetter if not present in cache.
/// The function can return NULL if the source string has no text for the given segment.
- (NSAttributedString *)stringForTextSegment:(TextSegment *)segment lineCount:(NSUInteger *)lines;

/// Enumerate throught text segments creating them if not yet present. This function
/// guarantee to enumerate throught all the text segments that cover the entire
/// source text.
- (void)generateTextSegmentsAndEnumerateUsingBlock:(void(^)(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop))block;

@end

#pragma mark - ECTextRendererLine Class continuation

@interface ECTextRendererLine () {
@public
    CTLineRef CTLine;
    CGFloat width;
    CGFloat ascent;
    CGFloat descent;
    BOOL hasNewLine;
}

@property (nonatomic) CTLineRef CTLine;

+ (id)textRendererLineWithCTLine:(CTLineRef)line hasNewLine:(BOOL)newLine;

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

/// Count of elements in renderedLines. Reading this property does not generate the rendered lines if not needed.
@property (nonatomic, readonly) NSUInteger renderedLineCount;

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
/// The block to apply will receive the line and its index as well as it's number
/// (that may differ from the index if line wraps occurred) and the Y offset of the line.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stop))block;

/// Enumerate all the lines in the text segment within the given segment-relative 
/// string range. The block will also receive the relative line string range.
- (void)enumerateLinesInStringRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

- (void)enumerateLinesInLineRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

@end


#pragma mark - Implementations

#pragma mark - ECTextRendererLine Implementation

@implementation ECTextRendererLine

@synthesize CTLine, width, ascent, descent, hasNewLine;

- (CGFloat)height
{
    return ascent + descent;
}

- (CGSize)size
{
    return CGSizeMake(width, ascent + descent);
}

+ (ECTextRendererLine *)textRendererLineWithCTLine:(CTLineRef)line hasNewLine:(BOOL)newLine
{
    ECASSERT(line != NULL);
    
    ECTextRendererLine *result = [ECTextRendererLine new];
    result->CTLine = CFRetain(line);
    result->width = CTLineGetTypographicBounds(line, &result->ascent, &result->descent, NULL);
    result->hasNewLine = newLine;
    return result;
}

- (void)dealloc
{
    if (CTLine)
        CFRelease(CTLine);
}

- (void)drawInContext:(CGContextRef)context
{
    CGRect runRect = CGRectMake(0, 0, width, ascent + descent);
    runRect.origin.y = -descent;
    CGFloat runWidth;
    
    CFArrayRef runs = CTLineGetGlyphRuns(CTLine);
    CFIndex runCount = CFArrayGetCount(runs);
    CTRunRef run;
    
    // Drawing text
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
}

- (CGRect)boundsForSubstringInRange:(NSRange)stringRange
{
    ECASSERT(NSMaxRange(stringRange) <= CTLineGetStringRange(CTLine).length);
    
    CFRange lineStringRange = CTLineGetStringRange(CTLine);
    
    CGRect result = CGRectMake(0, 0, 0, ascent + descent);
    
    if (stringRange.location > 0)
    {
        result.origin.x = CTLineGetOffsetForStringIndex(CTLine, lineStringRange.location + stringRange.location, NULL);
    }
    
    CFIndex stringRangeEnd = NSMaxRange(stringRange);
    if (stringRangeEnd < lineStringRange.length)
        result.size.width = CTLineGetOffsetForStringIndex(CTLine, lineStringRange.location + stringRangeEnd, NULL) - result.origin.x;
    else
        result.size.width = width - result.origin.x;
    
    return result;
}

@end


#pragma mark - TextSegment Implementation

@implementation TextSegment

#pragma mark TextSegment Properties

@synthesize lineCount, renderedLineCount, renderWrapWidth, stringLength, valid;

- (NSAttributedString *)string
{
    NSAttributedString *string = [parentRenderer.segmentStringsCache objectForKey:self];
    
    if (!string)
    {
        string = [parentRenderer stringForTextSegment:self lineCount:&lineCount];
        if (!string)
            return nil;
        
        stringLength = [string length];
        [parentRenderer.segmentStringsCache setObject:string forKey:self];
    }
    
    return string;
}

- (CTTypesetterRef)typesetter
{
    CTTypesetterRef t = (__bridge CTTypesetterRef)[parentRenderer.typesettersCache objectForKey:self];
    
    if (!t)
    {
        t = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.string);
        
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
        [self.string.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
            CFIndex lineLength = [line length], truncationLenght;
            do {
                // TODO possibly filter using customizable block
                truncationLenght = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, renderWrapWidth);
                
                // Generate line
                lineRange.length = truncationLenght;
                CTLineRef ctline = CTTypesetterCreateLine(typesetter, lineRange);
                lineRange.location += lineRange.length;
                
                // Save line
                [lines addObject:[ECTextRendererLine textRendererLineWithCTLine:ctline hasNewLine:(lineLength <= truncationLenght)]];
                lineLength -= truncationLenght;
                CFRelease(ctline);
            } while (lineLength > 0);
        }];
        
        // Cache result
        [parentRenderer.renderedLinesCache setObject:lines forKey:self];
        renderedLineCount = [lines count];
    }
    return lines;
}

- (NSUInteger)renderedLineCount
{
    if (renderedLineCount == 0)
        renderedLineCount = [self.renderedLines count];
    return renderedLineCount;
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
    for (ECTextRendererLine *line in self.renderedLines)
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

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(ECTextRendererLine *, NSUInteger, NSUInteger, CGFloat, BOOL *))block
{
    ECASSERT(valid);
    
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectInfinite;
    }
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    NSUInteger index = 0;
    NSUInteger number = 0;
    CGFloat currentY = 0, nextY;

    BOOL stop = NO;
    for (ECTextRendererLine *line in self.renderedLines)
    {
        nextY = currentY + line.height;
        if (nextY > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            //
            block(line, index, number, currentY, &stop);
            if (stop) break;
        }
        index++;
        number += line.hasNewLine;
        currentY = nextY;
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
    for (ECTextRendererLine *line in self.renderedLines)
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
    for (ECTextRendererLine *line in self.renderedLines)
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

@synthesize segmentStringsCache, typesettersCache, renderedLinesCache;
@synthesize delegate, datasource, preferredLineCountPerSegment, wrapWidth, estimatedHeight;

- (void)setDelegate:(id<ECTextRendererDelegate>)aDelegate
{
    delegate = aDelegate;
    flags.delegateHasTextInsetsForTextRenderer = [delegate respondsToSelector:@selector(textInsetsForTextRenderer:)];
    flags.delegateHasUnderlayPassesForTextRenderer = [delegate respondsToSelector:@selector(underlayPassesForTextRenderer:)];
    flags.delegateHasOverlayPassesForTextRenderer = [delegate respondsToSelector:@selector(overlayPassesForTextRenderer:)];
    flags.delegateHasTextRendererInvalidateRenderInRect = [delegate respondsToSelector:@selector(textRenderer:invalidateRenderInRect:)];
}

- (void)setDatasource:(id<ECTextRendererDataSource>)aDatasource
{
    if (datasource == aDatasource)
        return;
    
    datasource = aDatasource;
    
    flags.dataSourceHasTextRendererEstimatedTextLineCountOfLength = [datasource respondsToSelector:@selector(textRenderer:estimatedTextLineCountOfLength:)];
    
    [self updateAllText];
}

- (void)setWrapWidth:(CGFloat)width
{
    UIEdgeInsets textInsets = self.textInsets;
    width -= textInsets.left + textInsets.right;
    
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

// TODO: account for text insets
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
        segmentStringsCache = [NSCache new];
        segmentStringsCache.countLimit = 5;
        typesettersCache = [NSCache new];
        typesettersCache.countLimit = 5;
        renderedLinesCache = [NSCache new];
        renderedLinesCache.countLimit = 3;
    }
    return self;
}

- (UIEdgeInsets)textInsets
{
    if (flags.delegateHasTextInsetsForTextRenderer)
        return [delegate textInsetsForTextRenderer:self];
    return UIEdgeInsetsZero;
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
    @synchronized (textSegments)
    {
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
    //        currentLineRange.length = segment.lineCount;
            
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
}

#pragma mark Public Outtake Methods

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(ECTextRendererLine *, NSUInteger, NSUInteger, CGFloat, NSRange, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
        rect = CGRectInfinite;
    
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    [self generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineNumberOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stopInner) {
            lastLineEnd += line.height;
            
            CFRange stringRange = CTLineGetStringRange(line.CTLine);
            
            // TODO make an indexOffset that sums renderedLineCount from past segments
            block(line, lineIndex, lineNumberOffset + lineNumber, positionOffset + lineOffset, NSMakeRange(stringOffset + stringRange.location, stringRange.length), stopInner);
            *stop = *stopInner;
        }];
        
        // Stop if last line esceed the input rect
        if (lastLineEnd >= rectEnd)
            *stop = YES;
    }];
}

- (void)drawTextWithinRect:(CGRect)rect inContext:(CGContextRef)context
{
    ECASSERT(context != NULL);

    // Setup rendering transformations
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextScaleCTM(context, 1, -1);
    
    // Get text insets
    UIEdgeInsets textInsets = self.textInsets;
    rect.size.height -= textInsets.top;
    if (rect.origin.y > textInsets.top)
    {
        CGContextTranslateCTM(context, textInsets.left, 0);
        rect.origin.y -= textInsets.top;
    }
    else
    {
        rect.origin.y = 0;
        CGContextTranslateCTM(context, textInsets.left, -textInsets.top);
    }
    
    // Get rendering passes
    NSArray *underlays = flags.delegateHasUnderlayPassesForTextRenderer ? [delegate underlayPassesForTextRenderer:self] : nil;
    NSArray *overlays = flags.delegateHasOverlayPassesForTextRenderer ? [delegate overlayPassesForTextRenderer:self] : nil;
    
    // Draw needed lines from this segment
    [self enumerateLinesIntersectingRect:rect usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, NSRange stringRange, BOOL *stop) {
        CGRect lineBound = (CGRect){ CGPointMake(textInsets.left, lineOffset), line.size };
        
        // Move context to next line
        CGContextTranslateCTM(context, 0, -lineBound.size.height);
        
        // Require adjustment in rendering for first partial line
        if (lineBound.origin.y < rect.origin.y) 
        {
            CGContextTranslateCTM(context, 0, rect.origin.y - lineBound.origin.y);
        }
        
        // Apply underlay passes
        for (ECTextRendererLayerPass pass in underlays)
        {
            CGContextSaveGState(context);
            CGContextSetTextPosition(context, 0, 0);
            pass(context, line, lineBound, stringRange, lineNumber);
            CGContextRestoreGState(context);
        }
        
        // Rendering text
        CGContextSaveGState(context);
        CGContextSetTextPosition(context, 0, 0);
        CGContextTranslateCTM(context, 0, line.descent);
        [line drawInContext:context];
        CGContextRestoreGState(context);
        
        // Apply overlay passes
        for (ECTextRendererLayerPass pass in overlays)
        {
            CGContextSaveGState(context);
            CGContextSetTextPosition(context, 0, 0);
            pass(context, line, lineBound, stringRange, lineNumber);
            CGContextRestoreGState(context);
        }
    }];
}

- (NSUInteger)closestStringLocationToPoint:(CGPoint)point withinStringRange:(NSRange)queryStringRange
{
    point = [self convertToTextPoint:point];
    
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
            
            lineBounds = [self convertFromTextRect:lineBounds];
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
        
        [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(ECTextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stop) {
            CGSize lineSize = line.size;
            
            result.size.width = MAX(result.size.width, lineSize.width);
            result.size.height += lineSize.height;
            
            if (meanLineHeight > 0) 
            {
                meanLineHeight = (meanLineHeight + lineSize.height) / 2.0;
            }
            else
            {
                meanLineHeight = lineSize.height;
            }
            maxCharsForLine = MAX((CFIndex)maxCharsForLine, CTLineGetGlyphCount(line.CTLine));
        }];
    }
    
    // Guess remaining result
    if (guessed && lastSegmentEnd < CGRectGetMaxY(rect)) 
    {
        // Create datasource enabled guess
        if (flags.dataSourceHasTextRendererEstimatedTextLineCountOfLength) 
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
    
    UIEdgeInsets textInsets = self.textInsets;
    result.size.height += textInsets.top + textInsets.bottom;
    
    return result;
}

#pragma mark -

- (CGRect)convertFromTextRect:(CGRect)rect
{
    UIEdgeInsets textInsets = self.textInsets;
    rect.origin.x += textInsets.left;
    rect.origin.y += textInsets.top;
    return rect;
}

- (CGPoint)convertFromTextPoint:(CGPoint)point
{
    UIEdgeInsets textInsets = self.textInsets;
    point.x += textInsets.left;
    point.y += textInsets.top;
    return point;
}

- (CGRect)convertToTextRect:(CGRect)rect
{
    UIEdgeInsets textInsets = self.textInsets;
    rect.origin.x -= textInsets.left;
    rect.origin.y -= textInsets.top;
    return rect;
}

- (CGPoint)convertToTextPoint:(CGPoint)point
{
    UIEdgeInsets textInsets = self.textInsets;
    point.x -= textInsets.left;
    point.y -= textInsets.top;
    return point;
}

#pragma mark Public Intake Methods

- (void)updateAllText
{
    [self clearCache];
    [textSegments removeAllObjects];
    lastTextSegment = nil;
    
    if (flags.delegateHasTextRendererInvalidateRenderInRect) 
    {
        CGRect changedRect = CGRectMake(0, 0, wrapWidth, self.estimatedHeight);
        [delegate textRenderer:self invalidateRenderInRect:[self convertFromTextRect:changedRect]];
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
            
#warning NIK TODO!!! if lineCount > 1.5 * preferred -> split or merge if * 0.5
            // and remember to set proper lastTextSegment
            [segmentStringsCache removeObjectForKey:segment];
            [typesettersCache removeObjectForKey:segment];
            [renderedLinesCache removeObjectForKey:segment];
            // TODO!!! instead of cleaning the cache, use a segment method to update just those lines
        }
        
        currentLineLocation += segmentRange.length;
    }
    
    if (flags.delegateHasTextRendererInvalidateRenderInRect) 
    {
        [delegate textRenderer:self invalidateRenderInRect:[self convertFromTextRect:changedRect]];
    }
    
    [self willChangeValueForKey:@"estimatedHeight"];
    estimatedHeight = 0;
    [self didChangeValueForKey:@"estimatedHeight"];
}

- (void)clearCache
{
    [segmentStringsCache removeAllObjects];
    [typesettersCache removeAllObjects];
    [renderedLinesCache removeAllObjects];
}

@end
