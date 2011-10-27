//
//  ECTextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextRenderer.h"
#import "ECTextStyle.h"


@class TextSegment;
@class TextSegmentFrame;

#pragma mark - ECTextRenderer Interface (Class extension)

@interface ECTextRenderer () {
@private
    NSMutableArray *textSegments;
    TextSegment *lastTextSegment;
    
    BOOL delegateHasDidInvalidateRenderInRect;
}

/// Redefined to accept private changes.
@property (nonatomic) CGFloat renderHeight;

/// Gets the render width for the text considering the text insets
- (CGFloat)_wrapWidth;

/// Updates every segment wrap width with the given width accounting for text
/// insets and inform the delegate that the old rendering rect has changed.
- (void)_updateRenderWidth:(CGFloat)width;

/// Retrieve the string for the given text segment. Line count is an output parameter, pass NULL if not interested.
/// This function is supposed to be used by a text segment to generate it's typesetter if not present in cache.
/// The function can return nil if the source string has no text for the given segment.
- (NSAttributedString *)_stringForTextSegment:(TextSegment *)segment lineCount:(NSUInteger *)lines;

/// Enumerate throught text segments creating them if not yet present. This function
/// guarantee to enumerate throught all the text segments that cover the entire
/// source text.
- (void)_generateTextSegmentsAndEnumerateUsingBlock:(void(^)(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop))block;

/// Returns the line number of a given position in the text. Optionally returns
/// the X offset of the position in the returned line.
- (NSUInteger)_lineNumberForPosition:(NSUInteger)position offsetX:(CGFloat *)outXOffset;

/// Returns the text position of the given line and, withing that line, the character
/// at the specified X offset.
- (NSUInteger)_positionForLine:(NSUInteger)requestLine graphicalOffset:(CGFloat)offsetX;

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
@interface TextSegment : NSObject <NSDiscardableContent> {
@private
    NSInteger _discardableContentCount;
    ECTextRenderer *parentRenderer;
    
    // Content
    NSAttributedString *_string;
    CTTypesetterRef _typesetter;
    NSMutableArray *_renderedLines;
    
    /// Cache of heights for wrap widths
    struct { CGFloat wrapWidth; CGFloat height; } heightCache[HEIGHT_CACHE_SIZE];
}

- (id)initWithTextRenderer:(ECTextRenderer *)renderer;

#pragma mark Content

/// The string rendered with this text segment.
@property (nonatomic, strong) NSAttributedString *string;

/// The length of the receiver's string. Use this method instead of [string length]
/// to avoid calling on a deallocated cache.
@property (nonatomic) NSUInteger stringLength;

/// The typesetter generated from the text segment string.
@property (nonatomic) CTTypesetterRef typesetter;

/// Removes the content.
- (void)discardContent;

#pragma mark Derived Data

/// An array of rendered wrapped lines ready to be drawn on a context.
@property (nonatomic, strong) NSArray *renderedLines;

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

@synthesize string = _string, typesetter = _typesetter, renderedLines = _renderedLines;
@synthesize lineCount, renderedLineCount, renderWrapWidth, stringLength, valid;

- (NSAttributedString *)string
{
    ECASSERT(_discardableContentCount  > 0);
    
    if (!_string)
    {
        _string = [parentRenderer _stringForTextSegment:self lineCount:&lineCount];
        if (!_string)
            return nil;
        
        stringLength = [_string length];
        
        ECASSERT(_typesetter == NULL && "With typesetter there should be no way to reach this point");
    }
    
    return _string;
}

- (CTTypesetterRef)typesetter
{
    ECASSERT(_discardableContentCount > 0);
    
    if (!_typesetter)
    {
        _typesetter = CTTypesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.string);

        // Remove rendered lines
        self.renderedLines = nil;
    }
    
    return _typesetter;
}

- (void)setTypesetter:(CTTypesetterRef)typesetter
{
    if (typesetter == _typesetter)
        return;
    
    [self willChangeValueForKey:@"typesetter"];
    if (_typesetter)
        CFRelease(_typesetter);
    if (typesetter)
        _typesetter = CFRetain(typesetter);
    else
        _typesetter = NULL;
    [self didChangeValueForKey:@"typesetter"];
}

- (NSArray *)renderedLines
{
    ECASSERT(_discardableContentCount > 0);
    
    if (!_renderedLines)
    {
        // Retrieve typesetter and string
        CTTypesetterRef typesetter = self.typesetter;
        _renderedLines = [[NSMutableArray alloc] initWithCapacity:lineCount];
        
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
                [_renderedLines addObject:[ECTextRendererLine textRendererLineWithCTLine:ctline hasNewLine:(lineLength <= truncationLenght)]];
                lineLength -= truncationLenght;
                CFRelease(ctline);
            } while (lineLength > 0);
        }];
        
        // Cache result
        renderedLineCount = [_renderedLines count];
    }
    return _renderedLines;
}

- (NSUInteger)renderedLineCount
{
    if (renderedLineCount == 0)
        renderedLineCount = [self.renderedLines count];
    return renderedLineCount;
}

- (void)setRenderWrapWidth:(CGFloat)width
{
    if (renderWrapWidth == width) 
        return;
    
    renderWrapWidth = width;
    self.renderedLines = nil;
    self.typesetter = nil;
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
    [self beginContentAccess];
    for (ECTextRendererLine *line in self.renderedLines)
    {
        heightCache[cacheIdx].height += line->ascent + line->descent;
    }
    [self endContentAccess];
    
    return heightCache[cacheIdx].height;
}

#pragma mark NSDiscardableContent Methods

- (BOOL)beginContentAccess
{
    return ++_discardableContentCount;
}

- (void)endContentAccess
{
    ECASSERT(_discardableContentCount > 0);
    
    --_discardableContentCount;
}

- (BOOL)isContentDiscarded
{
    return _string == nil && _typesetter == NULL && _renderedLines == nil;
}

- (void)discardContentIfPossible
{
    ECASSERT(_discardableContentCount >= 0);
    
    if (_discardableContentCount > 0 || [self isContentDiscarded])
        return;
    
    [self discardContent];
}

#pragma mark Content Discarding

- (void)discardContent
{
    self.string = nil;
    self.renderedLines = nil;
    self.typesetter = nil;
}

- (void)dealloc
{
    [self discardContent];
}

#pragma mark TextSegment Methods

- (id)initWithTextRenderer:(ECTextRenderer *)renderer
{
    ECASSERT(renderer != nil);
    
    if ((self = [super init])) 
    {
        parentRenderer = renderer;
        
        // Will generate the segment derived data.
        [self beginContentAccess];
        valid = self.typesetter != NULL;
        [self endContentAccess];
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
        
        if (lineIndex >= queryRange.location) 
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

@synthesize delegate, datasource;
@synthesize renderWidth, renderHeight, textInsets, maximumStringLenghtPerSegment;
@synthesize underlayRenderingPasses, overlayRenderingPasses;

- (void)setDelegate:(id<ECTextRendererDelegate>)aDelegate
{
    if (aDelegate == delegate)
        return;
    
    [self willChangeValueForKey:@"delegate"];
    
    delegate = aDelegate;
    delegateHasDidInvalidateRenderInRect = [delegate respondsToSelector:@selector(textRenderer:didInvalidateRenderInRect:)];
    
    [self didChangeValueForKey:@"delegate"];
}

- (void)setDatasource:(id<ECTextRendererDataSource>)aDatasource
{
    if (datasource == aDatasource)
        return;
    
    [self willChangeValueForKey:@"datasource"];
    datasource = aDatasource;
    [self updateAllText];
    [self didChangeValueForKey:@"datasource"];
}

- (void)setRenderWidth:(CGFloat)width
{
    if (width == renderWidth)
        return;
    
    [self willChangeValueForKey:@"renderWidth"];
    
    // Order here mater because the update will inform the delegate that the old rendering rect changed. Than we update that rect size itself.
    [self _updateRenderWidth:width];
    renderWidth = width;
    
    [self didChangeValueForKey:@"renderWidth"];
}

- (void)setRenderHeight:(CGFloat)height
{
    if (height == renderHeight)
        return;
    
    [self willChangeValueForKey:@"renderHeight"];
    if (height > 0)
        renderHeight = height + textInsets.top + textInsets.bottom;
    else
        renderHeight = 0;
    [self didChangeValueForKey:@"renderHeight"];
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
    if (UIEdgeInsetsEqualToEdgeInsets(insets, textInsets))
        return;
    
    [self willChangeValueForKey:@"textInsets"];
    
    // Order matter, update will use textInsets to evalue wrap with for segments
    textInsets = insets;
    [self _updateRenderWidth:self.renderWidth];
    
    [self didChangeValueForKey:@"textInsets"];
}

#pragma mark NSObject Methods

- (id)init 
{
    if ((self = [super init])) 
    {
        textSegments = [NSMutableArray new];
    }
    return self;
}

#pragma mark Private Methods

- (CGFloat)_wrapWidth
{
    return renderWidth - textInsets.left - textInsets.right;
}

- (void)_updateRenderWidth:(CGFloat)width
{
    CGFloat wrapWidth = width - textInsets.left - textInsets.right;
    for (TextSegment *segment in textSegments) 
    {
        segment.renderWrapWidth = wrapWidth;
    }
    
    if (delegateHasDidInvalidateRenderInRect)
        [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, 0, self.renderWidth, self.renderHeight)];
}

- (NSAttributedString *)_stringForTextSegment:(TextSegment *)requestSegment lineCount:(NSUInteger *)lines
{    
    NSUInteger inputStringLenght = [datasource stringLengthForTextRenderer:self];
    if (inputStringLenght == 0)
        return nil;
    
    NSRange stringRange = NSMakeRange(0, 0);
    
    // Source text line offset for requested segment
    for (TextSegment *segment in textSegments) 
    {
        if (segment == requestSegment)
            break;
        stringRange.location += segment.stringLength;
    }
    
    // If the segment already has it's string length, it means that this request
    // has been done to refresh it. See updateTextFromStringRange:toStringRange:
    // to understand how this stringLenght is properly adjusted.
    stringRange.length = MIN((inputStringLenght - stringRange.location), (requestSegment.stringLength ? requestSegment.stringLength : maximumStringLenghtPerSegment));
    NSAttributedString *attributedString = [datasource textRenderer:self attributedStringInRange:stringRange];
    NSUInteger stringLength = [attributedString length];
    if (!attributedString || stringLength == 0)
        return nil;
    
    // Calculate the number of lines in the string
    NSString *string = attributedString.string;
    NSUInteger lineStart = 0, lineEnd = 0, contentsEnd;
    NSRange lineRange = NSMakeRange(0, 0);
    NSUInteger lineCount = 0;
    do {
        lineRange.location += lineEnd - lineStart;
        [string getLineStart:&lineStart end:&lineEnd contentsEnd:&contentsEnd forRange:lineRange];
    } while (lineEnd < stringLength && lineEnd != contentsEnd && ++lineCount);
    
    // Add tailing line if at the end of an actual line
    if (lineEnd != contentsEnd || inputStringLenght == NSMaxRange(stringRange))
    {
        lineRange.location += lineEnd - lineStart;
        lineCount++;
    }
    
    // Add a tailing new line 
    if (inputStringLenght == NSMaxRange(stringRange))
    {
        NSMutableAttributedString *newLineString = [attributedString mutableCopy];
        [newLineString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:[newLineString attributesAtIndex:stringLength - 1 effectiveRange:NULL]]];
        attributedString = newLineString;
    }

    // Side effect! clear caches if segment changes its ragne
    if (requestSegment.lineCount > 0 && lineCount != requestSegment.lineCount)
    {
        [self clearCache];
    }
    
    // Trim returned string if needed
    if (lineRange.location != stringLength)
        attributedString = [attributedString attributedSubstringFromRange:NSMakeRange(0, lineRange.location)];
    
    if (lines)
        *lines = lineCount;
    
    return attributedString;
}

- (void)_generateTextSegmentsAndEnumerateUsingBlock:(void (^)(TextSegment *, NSUInteger, NSUInteger, NSUInteger, CGFloat, BOOL *))block
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
                segment.renderWrapWidth = [self _wrapWidth];
                [segment beginContentAccess];
                if (!segment.isValid) 
                {
                    lastTextSegment = [textSegments lastObject];
                    break;
                }
                else if ((currentStringOffset + [segment.string length]) >= [datasource stringLengthForTextRenderer:self])
                {
                    lastTextSegment = segment;
                }
                
                [textSegments addObject:segment];
            }
            else
            {
                segment = [textSegments objectAtIndex:currentIndex];
                [segment beginContentAccess];
            }

            // Apply block
            block(segment, currentIndex, currentLineRange.location, currentStringOffset, currentPositionOffset, &stop);
            
            // Update offsets
            currentIndex++;
            currentLineRange.length = segment.lineCount;
            currentLineRange.location += currentLineRange.length;
            currentStringOffset += segment.stringLength;
            currentPositionOffset += segment.renderHeight;
            
            [segment endContentAccess];
            
        } while (!stop);
        
        // Update estimated height
        if (currentPositionOffset > renderHeight 
            || (lastTextSegment == segment && currentPositionOffset != renderHeight)) 
        {
            self.renderHeight = currentPositionOffset;
        }
    }
}

- (NSUInteger)_lineNumberForPosition:(NSUInteger)position offsetX:(CGFloat *)outXOffset
{
    __block CGFloat positionX = 0;
    __block NSUInteger positionLine = NSUIntegerMax;
    [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
    
    if (outXOffset)
        *outXOffset = positionX;
    return positionLine;
}

- (NSUInteger)_positionForLine:(NSUInteger)requestLine graphicalOffset:(CGFloat)offsetX
{
    __block CGFloat positionX = offsetX;
    __block NSUInteger requestPosition = NSNotFound;
    [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
    
    return requestPosition;
}

#pragma mark Public Outtake Methods

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(ECTextRendererLine *, NSUInteger, NSUInteger, CGFloat, NSRange, BOOL *))block
{
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
        rect = CGRectInfinite;
    
    CGFloat rectEnd = CGRectGetMaxY(rect);
    
    [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineNumberOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
        for (ECTextRendererLayerPass pass in underlayRenderingPasses)
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
        for (ECTextRendererLayerPass pass in overlayRenderingPasses)
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
    [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
    [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
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
            CGFloat positionX = 0;
            NSUInteger positionLine = [self _lineNumberForPosition:position offsetX:&positionX];
            
            // If offset will move outsite rendered text line range, return
            if (offset < 0 && -offset > (NSInteger)positionLine)
                break;
            
            // Look for new position
            NSUInteger requestPosition = [self _positionForLine:(positionLine + offset) graphicalOffset:positionX];
            
            // Set result if present
            if (requestPosition != NSNotFound)
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

#pragma mark -

- (CGRect)convertFromTextRect:(CGRect)rect
{
    rect.origin.x += textInsets.left;
    rect.origin.y += textInsets.top;
    return rect;
}

- (CGPoint)convertFromTextPoint:(CGPoint)point
{
    point.x += textInsets.left;
    point.y += textInsets.top;
    return point;
}

- (CGRect)convertToTextRect:(CGRect)rect
{
    rect.origin.x -= textInsets.left;
    rect.origin.y -= textInsets.top;
    return rect;
}

- (CGPoint)convertToTextPoint:(CGPoint)point
{
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
    
    if (delegateHasDidInvalidateRenderInRect) 
        [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, 0, self.renderWidth, self.renderHeight)];
}

- (void)updateTextFromStringRange:(NSRange)fromRange toStringRange:(NSRange)toRange
{
    // Calculate change withing single semgment
    NSInteger segmentIndex = -1, removeFromSegmentIndex = NSNotFound;
    CGFloat affectedSegmentHeight = 0, removeFromSegmentYOffset = 0;
    NSRange segmentRange = NSMakeRange(0, 0);
    NSUInteger fromRangeEnd = NSMaxRange(fromRange), segmentRangeEnd;
    for (TextSegment *segment in textSegments)
    {
        segmentIndex++;
        segmentRange.location += segmentRange.length;
        segmentRange.length = segment.stringLength;
        segmentRangeEnd = NSMaxRange(segmentRange);
        affectedSegmentHeight = segment.renderHeight;
        
        // Skip untouched segments
        ECASSERT(segmentRange.location < fromRangeEnd);
        if (segmentRangeEnd >= fromRange.location)
        {
            // Will remove every segment after the current if changes are crossing multiple segments
            if (fromRange.location < segmentRangeEnd
                && fromRangeEnd >= segmentRangeEnd)
            {
                removeFromSegmentIndex = segmentIndex;
                break;
            }
            
            // Will remove segment if modifying it will change it's string lenght too much
            NSInteger segmentNewLength = segment.stringLength + (toRange.length - fromRange.length);
            if (segmentNewLength > maximumStringLenghtPerSegment * 1.5 
                || (segment != lastTextSegment && segmentNewLength < maximumStringLenghtPerSegment / 2))
            {
                removeFromSegmentIndex = segmentIndex;
                break;
            }
            
            // Only one segment is affected
            segment.stringLength = segmentNewLength;
            [segment discardContent];
            break;
        }
        
        removeFromSegmentYOffset += affectedSegmentHeight;
    }
    
    // If the change crosses multiple segments, recreate all from the one where the change start
    if (removeFromSegmentIndex != NSNotFound)
    {
        [textSegments removeObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(removeFromSegmentIndex, [textSegments count] - removeFromSegmentIndex)]];
        lastTextSegment = nil;
    }
    
    // Send invalidation for specific rect
    if (delegateHasDidInvalidateRenderInRect)
        [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, removeFromSegmentYOffset, self.renderWidth, (removeFromSegmentIndex != NSNotFound ? self.renderHeight - removeFromSegmentYOffset : affectedSegmentHeight))];
}

- (void)clearCache
{
    for (TextSegment *segment in textSegments)
    {
        [segment discardContentIfPossible];
    }
}

@end
