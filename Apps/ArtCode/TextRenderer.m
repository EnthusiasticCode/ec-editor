//
//  TextRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 16/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextRenderer.h"

NSString * const TextRendererRunBackgroundColorAttributeName = @"runBackground";
NSString * const TextRendererRunOverlayBlockAttributeName = @"runOverlayBlock";
NSString * const TextRendererRunUnderlayBlockAttributeName = @"runUnderlayBlock";
NSString * const TextRendererRunDrawBlockAttributeName = @"runDrawBlock";

@class TextSegment;
@class TextSegmentFrame;

@interface TextRenderer ()

/// Redefined to accept private changes.
@property (nonatomic) CGFloat renderHeight;

/// Gets the render width for the text considering the text insets
- (CGFloat)_wrapWidth;

/// Updates every segment wrap width with the given width accounting for text
/// insets and inform the delegate that the old rendering rect has changed.
- (void)_updateRenderWidth:(CGFloat)width;

/// Retrieve the string for the given text segment. 
/// lineCount is an output parameter, pass NULL if not interested.
/// isFinalPart, if provided, will contain a value indicating if the input string has been exausted with the call. 
/// This function is supposed to be used by a text segment to generate it's typesetter if not present in cache.
/// The function can return nil if the source string has no text for the given segment.
- (NSAttributedString *)_stringForTextSegment:(TextSegment *)segment lineCount:(NSUInteger *)lines finalPart:(BOOL *)isFinalPart;

/// Enumerate throught text segments creating them if not yet present. This function
/// guarantee to enumerate throught all the text segments that cover the entire
/// source text.
- (void)_generateTextSegmentsAndEnumerateUsingBlock:(void(^)(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop))block;

/// Returns the line number of a given position in the text. Optionally returns
/// the X offset of the position in the returned line.
- (NSUInteger)_renderedLineIndexFromPosition:(NSUInteger)position graphicalOffset:(CGFloat *)outXOffset;

/// Returns the text position of the given line and, withing that line, the character
/// at the specified X offset.
- (NSUInteger)_positionFromRenderedLineAtIndex:(NSUInteger)requestLine graphicalOffset:(CGFloat)offsetX;

@end

#pragma mark - TextRendererLine Class continuation

@interface TextRendererLine () {
@public
  CTLineRef CTLine;
  CGFloat width;
  CGFloat ascent;
  CGFloat descent;
  CGFloat leading;
  BOOL isTruncation;
}

@property (nonatomic) CTLineRef CTLine;

+ (id)textRendererLineWithCTLine:(CTLineRef)line font:(CTFontRef)font isTruncation:(BOOL)truncation;

@end

#pragma mark - TextSegment Interface

#define HEIGHT_CACHE_SIZE (3)

/// A Text Segment represent a part of the text rendered. The segment represented
/// text is limited by the number of lines in \c preferredLineCountPerSegment.
@interface TextSegment : NSObject <NSDiscardableContent> {
@private
  NSInteger _discardableContentCount;
  TextRenderer *parentRenderer;
  
  // Content
  NSAttributedString *_string;
  CTTypesetterRef _typesetter;
  NSMutableArray *_renderedLines;
  
  /// Cache of heights for wrap widths
  struct { CGFloat wrapWidth; CGFloat height; } heightCache[HEIGHT_CACHE_SIZE];
}

- (id)initWithTextRenderer:(TextRenderer *)renderer;

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

/// Indicates if this segment is the last one.
@property (nonatomic, readonly, getter = isLastSegment) BOOL lastSegment;

/// The current render width. Changing this property will make the segment to
/// generate a new frame if no one with this width is present in cache.
@property (nonatomic) CGFloat renderWrapWidth;

/// The actual render height of the whole string in the segment at the current
/// wrap width.
@property (nonatomic, readonly) CGFloat renderSegmentHeight;

/// Enumerate all the rendered lines in the text segment that intersect the given rect. 
/// The rect should be relative to this segment coordinates.
/// The block to apply will receive the line and its index as well as it's number
/// (that may differ from the index if line wraps occurred) and the Y offset of the line.
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stop))block;

/// Enumerate all the lines in the text segment within the given segment-relative 
/// string range. The block will also receive the relative line string range.
- (void)enumerateLinesInStringRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

- (void)enumerateLinesInRenderedLineIndexRange:(NSRange)range usingBlock:(void(^)(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stop))block;

@end


#pragma mark - Implementations

#pragma mark - TextRendererLine Implementation

@implementation TextRendererLine

@synthesize CTLine, width, ascent, descent, isTruncation;

- (CGFloat)height
{
  return ascent + descent + leading;
}

- (CGSize)size
{
  return CGSizeMake(width, ascent + descent + leading);
}

+ (TextRendererLine *)textRendererLineWithCTLine:(CTLineRef)line font:(CTFontRef)font isTruncation:(BOOL)truncation
{
  ASSERT(line != NULL);
  
  TextRendererLine *result = [TextRendererLine new];
  result->CTLine = CFRetain(line);
  result->width = CTLineGetTypographicBounds(line, &result->ascent, &result->descent, &result->leading);
  result->isTruncation = truncation;
  
  // Fixing problem with new-lines not retaining font attribute
  if (font)
  {
    CGFloat fix = CTFontGetAscent(font);
    if (result->ascent < fix)
      result->ascent = fix;
    fix = CTFontGetDescent(font);
    if (result->descent < fix)
      result->descent = fix;
    fix = CTFontGetLeading(font);
    if (result->leading < fix)
      result->leading = fix;
  }
  
  return result;
}

- (void)dealloc
{
  if (CTLine)
    CFRelease(CTLine);
}

- (void)drawInContext:(CGContextRef)context
{
  CGRect runRect = CGRectMake(0, 0, width, ascent + descent + leading);
  runRect.origin.y = -descent;
  CGFloat runWidth;
  
  CFArrayRef runs = CTLineGetGlyphRuns(CTLine);
  CFIndex runCount = CFArrayGetCount(runs);
  CTRunRef run;
  
  // Drawing text
  NSDictionary *runAttributes;
  TextRendererRunBlock block;
  for (CFIndex i = 0; i < runCount; ++i) 
  {
    run = CFArrayGetValueAtIndex(runs, i);
    
    // Get run width
    runWidth = CTRunGetTypographicBounds(run, (CFRange){0, 0}, NULL, NULL, NULL);
    runRect.size.width = runWidth;
    runAttributes = (__bridge NSDictionary *)CTRunGetAttributes(run);
    
    // Apply custom back attributes
    if (runAttributes)
    {
      CGColorRef backgroundColor = (__bridge CGColorRef)[runAttributes objectForKey:TextRendererRunBackgroundColorAttributeName];
      if (backgroundColor) 
      {
        CGContextSetFillColorWithColor(context, backgroundColor);
        if (i == runCount - 1)
        {
          CGContextFillRect(context, (CGRect){ runRect.origin, CGSizeMake(1024, runRect.size.height) });
        }
        else
        {
          CGContextFillRect(context, runRect);
        }
      }
      block = [runAttributes objectForKey:TextRendererRunUnderlayBlockAttributeName];
      if (block) 
      {
        CGContextSaveGState(context);
        block(context, run, runRect, descent);
        CGContextRestoreGState(context);
      }
    }
    
    // Draw run
    block = [runAttributes objectForKey:TextRendererRunDrawBlockAttributeName];
    if (block)
    {
      CGContextSaveGState(context);
      block(context, run, runRect, descent);
      CGContextRestoreGState(context);
    }
    else
    {
      CTRunDraw(run, context, (CFRange){ 0, 0 });
    }
    
    // Apply custom front attributes
    if (runAttributes) 
    {
      NSNumber *underlineStyle = [runAttributes objectForKey:(__bridge id)kCTUnderlineStyleAttributeName];
      if (underlineStyle)
      {
        unsigned underline = [underlineStyle unsignedIntValue];
        CGColorRef underlineColor = (__bridge CGColorRef)[runAttributes objectForKey:(__bridge id)kCTUnderlineColorAttributeName];
        if (!underlineColor)
          underlineColor = (__bridge CGColorRef)[runAttributes objectForKey:(__bridge id)kCTForegroundColorAttributeName];
        CGContextSetStrokeColorWithColor(context, underlineColor);
        
        CGFloat ty = CGContextGetCTM(context).ty;
        CGFloat underlineY = (1.0 - (ty - floorf(ty))) + floorf(runRect.origin.y) + ((underline & kCTUnderlineStyleThick) ? 0 : 0.5);
        CGContextSetLineWidth(context, (underline & kCTUnderlineStyleThick) ? 2 : 1);
        
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, runRect.origin.x, underlineY);
        CGContextAddLineToPoint(context, runRect.origin.x + runWidth, underlineY);
        CGContextStrokePath(context);
      }
      block = [runAttributes objectForKey:TextRendererRunOverlayBlockAttributeName];
      if (block)
      {
        CGContextSaveGState(context);
        block(context, run, runRect, descent);
        CGContextRestoreGState(context);
      }
    }
    
    // Advance run origin
    runRect.origin.x += runWidth;
  }
}

- (CGRect)boundsForSubstringInRange:(NSRange)stringRange
{
  ASSERT((CFIndex)NSMaxRange(stringRange) <= CTLineGetStringRange(CTLine).length);
  
  CFRange lineStringRange = CTLineGetStringRange(CTLine);
  
  CGRect result = CGRectMake(0, 0, 0, ascent + descent + leading);
  
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
@synthesize lineCount, renderedLineCount, renderWrapWidth, stringLength, valid, lastSegment;

- (NSAttributedString *)string
{
  ASSERT(_discardableContentCount  > 0);
  
  if (!_string)
  {
    _string = [parentRenderer _stringForTextSegment:self lineCount:&lineCount finalPart:&lastSegment];
    if (!_string)
      return nil;
    
    stringLength = [_string length];
    
    ASSERT(_typesetter == NULL && "With typesetter there should be no way to reach this point");
  }
  
  return _string;
}

- (CTTypesetterRef)typesetter
{
  ASSERT(_discardableContentCount > 0);
  
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
  
  if (_typesetter)
    CFRelease(_typesetter);
  if (typesetter)
    _typesetter = CFRetain(typesetter);
  else
    _typesetter = NULL;
}

- (NSArray *)renderedLines
{
  ASSERT(_discardableContentCount > 0);
  
  if (!_renderedLines)
  {
    // Retrieve typesetter and string
    CTTypesetterRef typesetter = self.typesetter;
    _renderedLines = [[NSMutableArray alloc] initWithCapacity:lineCount];
    
    // Generate wrapped lines
    __block CFRange lineRange = CFRangeMake(0, 0);
    CTFontRef font = (__bridge CTFontRef)[self.string attribute:(__bridge NSString *)kCTFontAttributeName atIndex:0 effectiveRange:NULL];
    [self.string.string enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
      CFIndex lineLength = [line length], truncationLenght;
      BOOL truncation = NO;
      do {
        // TODO possibly filter using customizable block
        truncationLenght = CTTypesetterSuggestLineBreak(typesetter, lineRange.location, renderWrapWidth);
        
        // Generate line
        lineRange.length = truncationLenght;
        CTLineRef ctline = CTTypesetterCreateLine(typesetter, lineRange);
        lineRange.location += lineRange.length;
        
        // Save line
        [_renderedLines addObject:[TextRendererLine textRendererLineWithCTLine:ctline font:lineLength ? nil : font isTruncation:truncation]];
        truncation = YES;
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

- (CGFloat)renderSegmentHeight
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
  for (TextRendererLine *line in self.renderedLines)
  {
    heightCache[cacheIdx].height += line->ascent + line->descent + line->leading;
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
  ASSERT(_discardableContentCount > 0);
  
  --_discardableContentCount;
}

- (BOOL)isContentDiscarded
{
  return _string == nil && _typesetter == NULL && _renderedLines == nil;
}

- (void)discardContentIfPossible
{
  ASSERT(_discardableContentCount >= 0);
  
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
  heightCache[0].wrapWidth = 0;
  heightCache[1].wrapWidth = 0;
  heightCache[2].wrapWidth = 0;
}

- (void)dealloc
{
  [self discardContent];
}

#pragma mark TextSegment Methods

- (id)initWithTextRenderer:(TextRenderer *)renderer
{
  ASSERT(renderer != nil);
  
  if (!(self = [super init]))
    return nil;
  
  parentRenderer = renderer;
  
  // Will generate the segment derived data.
  [self beginContentAccess];
  valid = self.typesetter != NULL;
  if (!valid)
    lastSegment = YES;
  
  return self;
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(TextRendererLine *, NSUInteger, NSUInteger, CGFloat, BOOL *))block
{
  ASSERT(valid);
  
  if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
  {
    rect = CGRectInfinite;
  }
  CGFloat rectEnd = CGRectGetMaxY(rect);
  
  NSUInteger index = 0;
  NSUInteger number = 0;
  CGFloat currentY = 0, nextY;
  
  BOOL stop = NO;
  for (TextRendererLine *line in self.renderedLines)
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
    if (!line.isTruncation)
      ++number;
    currentY = nextY;
  }
}

- (void)enumerateLinesInStringRange:(NSRange)queryRange usingBlock:(void (^)(CTLineRef, NSUInteger, CGRect, NSRange, BOOL *))block
{
  ASSERT(valid);
  
  NSUInteger queryRangeEnd = NSUIntegerMax;
  if (queryRange.length > 0)
    queryRangeEnd = queryRange.location + queryRange.length;
  
  CGFloat currentY = 0;
  CGRect bounds;
  CFRange stringRange;
  NSUInteger lineIndex = 0;
  
  BOOL stop = NO;
  for (TextRendererLine *line in self.renderedLines)
  {
    stringRange = CTLineGetStringRange(line->CTLine);
    if ((NSUInteger)stringRange.location >= queryRangeEnd)
      return;
    
    bounds = CGRectMake(0, currentY, line->width, line->ascent + line->descent + line->leading);
    
    if ((NSUInteger)(stringRange.location + stringRange.length) > queryRange.location) 
    {
      block(line->CTLine, lineIndex, bounds, (NSRange){ stringRange.location, stringRange.length }, &stop);
      if (stop) break;
    }
    
    currentY += bounds.size.height;
    lineIndex++;
  }
}

- (void)enumerateLinesInRenderedLineIndexRange:(NSRange)queryRange usingBlock:(void (^)(CTLineRef, NSUInteger, CGRect, NSRange, BOOL *))block
{
  ASSERT(valid);
  
  NSUInteger queryRangeEnd = NSUIntegerMax;
  if (queryRange.length > 0)
    queryRangeEnd = queryRange.location + queryRange.length;
  
  CGFloat currentY = 0;
  CGRect bounds;
  CFRange stringRange;
  NSUInteger lineIndex = 0;
  
  BOOL stop = NO;
  for (TextRendererLine *line in self.renderedLines)
  {
    if ((CFIndex)lineIndex >= (CFIndex)queryRangeEnd) 
      return;
    
    stringRange = CTLineGetStringRange(line->CTLine);
    
    bounds = CGRectMake(0, currentY, line->width, line->ascent + line->descent + line->leading);
    
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
#pragma mark TextRenderer Implementation


@implementation TextRenderer {
@private
  NSMutableArray *textSegments;
  dispatch_semaphore_t textSegmentsSemaphore;
  
  BOOL _needsUpdate;
  BOOL delegateHasDidInvalidateRenderInRect;
  
  id _notificationCenterMemoryWarningObserver;
}

#pragma mark Properties

@synthesize delegate, text = _text, defaultTextAttributes = _defaultTextAttributes;
@synthesize renderWidth, renderHeight, renderTextHeight, textInsets, maximumStringLenghtPerSegment;
@synthesize underlayRenderingPasses, overlayRenderingPasses;

- (void)setText:(NSAttributedString *)text {
  if (text == _text)
    return;
  
  _text = text;
  [self setNeedsUpdate];
  
  if (delegateHasDidInvalidateRenderInRect) 
    [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, 0, self.renderWidth, self.renderHeight)];
}

- (void)setDelegate:(id<TextRendererDelegate>)aDelegate
{
  if (aDelegate == delegate)
    return;
  
  delegate = aDelegate;
  delegateHasDidInvalidateRenderInRect = [delegate respondsToSelector:@selector(textRenderer:didInvalidateRenderInRect:)];
}

- (void)setRenderWidth:(CGFloat)width
{
  if (width == renderWidth)
    return;
  
  // Order here mater because the update will inform the delegate that the old rendering rect changed. Than we update that rect size itself.
  [self _updateRenderWidth:width];
  renderWidth = width;
  
  if (delegateHasDidInvalidateRenderInRect)
    [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, 0, self.renderWidth, self.renderHeight)];
}

- (void)setRenderTextHeight:(CGFloat)height
{
  if (height == renderTextHeight)
    return;
  
  renderTextHeight = height;
  self.renderHeight = height + textInsets.top + textInsets.bottom;
}

- (BOOL)isRenderHeightFinal
{
  return textSegments && [[textSegments lastObject] isLastSegment];
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
  if (UIEdgeInsetsEqualToEdgeInsets(insets, textInsets))
    return;
  
  // Order matter, update will use textInsets to evalue wrap with for segments
  textInsets = insets;
  [self _updateRenderWidth:self.renderWidth];
  
  if (delegateHasDidInvalidateRenderInRect)
    [delegate textRenderer:self didInvalidateRenderInRect:CGRectMake(0, 0, self.renderWidth, self.renderHeight)];
}

#pragma mark NSObject Methods

- (id)init 
{
  if (!(self = [super init])) 
    return nil;
  
  textSegments = [NSMutableArray new];
  textSegmentsSemaphore = dispatch_semaphore_create(1);
  
  __weak TextRenderer *this = self;
  _notificationCenterMemoryWarningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    if (dispatch_semaphore_wait(textSegmentsSemaphore, dispatch_time(DISPATCH_TIME_NOW, 5 * 1000 * 1000)) != 0)
      return;
    
    for (TextSegment *segment in this->textSegments)
    {
      [segment discardContentIfPossible];
    }
    
    dispatch_semaphore_signal(textSegmentsSemaphore);
  }];
  
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:_notificationCenterMemoryWarningObserver];
  dispatch_release(textSegmentsSemaphore);
}

#pragma mark Private Methods

- (CGFloat)_wrapWidth
{
  return renderWidth - textInsets.left - textInsets.right;
}

- (void)_updateRenderWidth:(CGFloat)width
{
  CGFloat wrapWidth = width - textInsets.left - textInsets.right;
  dispatch_semaphore_wait(textSegmentsSemaphore, DISPATCH_TIME_FOREVER);
  {
    for (TextSegment *segment in textSegments) 
    {
      segment.renderWrapWidth = wrapWidth;
    }
  }
  dispatch_semaphore_signal(textSegmentsSemaphore);
}

// Already locked in _generateTextSegmentsAndEnumerateUsingBlock
- (NSAttributedString *)_stringForTextSegment:(TextSegment *)requestSegment lineCount:(NSUInteger *)lines finalPart:(BOOL *)isFinalPart
{
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
// TODO BOTH rename in textRenderer:attributedStringInPreferredRange: to internally check for consistency to avoid race conditions
  NSUInteger inputStringLenght = self.text.length;
  stringRange.length = MIN((inputStringLenght - stringRange.location), (requestSegment.stringLength ? requestSegment.stringLength : maximumStringLenghtPerSegment));
  NSAttributedString *attributedString = [self.text attributedSubstringFromRange:stringRange];
  NSUInteger stringLength = [attributedString length];
  
  // Calculate the number of lines in lineCount 
  // and the end of useful string in lineRange.location
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
  
  // Trim returned string if needed
  if (lineRange.location != stringLength)
    attributedString = [attributedString attributedSubstringFromRange:NSMakeRange(0, lineRange.location)];
  
  // Add a tailing new line 
  else if (inputStringLenght == NSMaxRange(stringRange))
  {
    NSMutableAttributedString *newLineString = [attributedString mutableCopy];
    [newLineString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:self.defaultTextAttributes]];
    attributedString = newLineString;
    
    if (isFinalPart)
      *isFinalPart = YES;
  }
  
  // Side effect! clear caches if segment changes its range
  if (requestSegment.lineCount > 0 && lineCount != requestSegment.lineCount)
  {
    NSUInteger requestSegmentIndex = [textSegments indexOfObject:requestSegment];
    [textSegments enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(requestSegmentIndex, [textSegments count] - requestSegmentIndex)] options:0 usingBlock:^(TextSegment *segment, NSUInteger idx, BOOL *stop) {
      [segment discardContent];
    }];
  }
  
  if (lines)
    *lines = lineCount;
  
  return attributedString;
}

- (void)_generateTextSegmentsAndEnumerateUsingBlock:(void (^)(TextSegment *, NSUInteger, NSUInteger, NSUInteger, CGFloat, BOOL *))block
{
  // Update if neccessary
  for (;;) {
    dispatch_semaphore_wait(textSegmentsSemaphore, DISPATCH_TIME_FOREVER);
    {
      if (_needsUpdate) {
        for (TextSegment *segment in textSegments) {
          [segment discardContent];
        }
        
        [textSegments removeAllObjects];
        _needsUpdate = NO;
      } else {
        dispatch_semaphore_signal(textSegmentsSemaphore);
        break;
      }
    }
    dispatch_semaphore_signal(textSegmentsSemaphore);
  }
    
  
  // Enumeration
  BOOL stop = NO;
  TextSegment *segment = nil;
  NSUInteger currentIndex = 0;
  NSRange currentLineRange = NSMakeRange(0, 0);
  NSUInteger currentStringOffset = 0;
  CGFloat currentPositionOffset = 0;
  do
  {
    dispatch_semaphore_wait(textSegmentsSemaphore, DISPATCH_TIME_FOREVER);
    
    // Generate segment if needed
    if ([textSegments count] <= currentIndex) 
    {
      segment = [[TextSegment alloc] initWithTextRenderer:self];
      segment.renderWrapWidth = [self _wrapWidth];
      if (!segment.isValid)
      {
        dispatch_semaphore_signal(textSegmentsSemaphore);
        break;
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
    currentPositionOffset += segment.renderSegmentHeight;
    
    [segment endContentAccess];
    
    dispatch_semaphore_signal(textSegmentsSemaphore);
    
  } while (!stop && !segment.isLastSegment);
  
  // Update estimated height
  if (currentPositionOffset > renderTextHeight 
      || (segment.isLastSegment && currentPositionOffset != renderTextHeight)) 
  {
    self.renderTextHeight = currentPositionOffset;
  }
}

- (NSUInteger)_renderedLineIndexFromPosition:(NSUInteger)position graphicalOffset:(CGFloat *)outXOffset
{
  __block CGFloat positionX = 0;
  __block NSUInteger renderedLineIndex = 0;
  [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
    // Skip segment if before required string range
    if (stringOffset + segment.stringLength <= position)
    {
      renderedLineIndex += segment.renderedLineCount;
      return;
    }
    
    // Get relative positions to current semgnet
    NSRange segmentRelativeStringRange = NSMakeRange(position, 0);
    segmentRelativeStringRange.location -= stringOffset;
    
    // Retrieve start position line index
    [segment enumerateLinesInStringRange:segmentRelativeStringRange usingBlock:^(CTLineRef line, NSUInteger innerIdx, CGRect lineBounds, NSRange lineStringRange, BOOL *innserStop) {
      renderedLineIndex += innerIdx;
      
      positionX = CTLineGetOffsetForStringIndex(line, (position - stringOffset), NULL);
      positionX += lineBounds.origin.x;
      
      *stop = *innserStop = YES;
    }];
  }];
  
  if (outXOffset)
    *outXOffset = positionX;
  return renderedLineIndex;
}

- (NSUInteger)_positionFromRenderedLineAtIndex:(NSUInteger)requestIndex graphicalOffset:(CGFloat)offsetX
{
  __block CGFloat positionX = offsetX;
  __block NSUInteger requestPosition = NSNotFound;
  __block NSUInteger lineIndexOffset = 0;
  [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger idx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
    // Skip segment if before required line
    if (lineIndexOffset + segment.renderedLineCount <= requestIndex)
    {
      lineIndexOffset += segment.renderedLineCount; 
      return;
    }
    
    // Get relative positions to current semgnet
    NSRange segmentRelativeLineRange = NSMakeRange(requestIndex, 1);
    segmentRelativeLineRange.location -= lineIndexOffset;
    
    // Retrieve start position line index
    [segment enumerateLinesInRenderedLineIndexRange:segmentRelativeLineRange usingBlock:^(CTLineRef line, NSUInteger lineNumber, CGRect lineBounds, NSRange lineStringRange, BOOL *stopInner) {
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

#pragma mark Public Methods

- (void)setNeedsUpdate {
  dispatch_semaphore_wait(textSegmentsSemaphore, DISPATCH_TIME_FOREVER);
  {
    _needsUpdate = YES;
  }
  dispatch_semaphore_signal(textSegmentsSemaphore);
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(TextRendererLine *, NSUInteger, NSUInteger, CGFloat, NSRange, BOOL *))block
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
    if (rect.origin.y > positionOffset + segment.renderSegmentHeight)
      return;
    
    // Adjust rect to current segment relative coordinates
    CGRect currentRect = rect;
    currentRect.origin.y -= positionOffset;
    
    // Enumerate needed lines from this segment
    __block CGFloat lastLineEnd = rect.origin.y;
    [segment enumerateLinesIntersectingRect:currentRect usingBlock:^(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, BOOL *stopInner) {
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
  ASSERT(context != NULL);
  
  // Setup rendering transformations
  CGContextSetTextMatrix(context, CGAffineTransformIdentity);
  CGContextScaleCTM(context, 1, -1);
  
  // Get text insets
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
  [self enumerateLinesIntersectingRect:rect usingBlock:^(TextRendererLine *line, NSUInteger lineIndex, NSUInteger lineNumber, CGFloat lineOffset, NSRange stringRange, BOOL *stop) {
    CGRect lineBound = (CGRect){ CGPointMake(textInsets.left, lineOffset), line.size };
    
    // Move context to next line
    CGContextTranslateCTM(context, 0, -lineBound.size.height);
    
    // Require adjustment in rendering for first partial line
    if (lineBound.origin.y < rect.origin.y) 
    {
      CGContextTranslateCTM(context, 0, rect.origin.y - lineBound.origin.y);
    }
    
    // Apply underlay passes
    for (TextRendererLayerPass pass in underlayRenderingPasses)
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
    for (TextRendererLayerPass pass in overlayRenderingPasses)
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

- (RectSet *)rectsForStringRange:(NSRange)queryStringRange limitToFirstLine:(BOOL)limit
{
  MutableRectSet *result = [MutableRectSet rectSetWithCapacity:1];
  [self _generateTextSegmentsAndEnumerateUsingBlock:^(TextSegment *segment, NSUInteger outerIdx, NSUInteger lineOffset, NSUInteger stringOffset, CGFloat positionOffset, BOOL *stop) {
    // Skip segment if before required string range
    if (stringOffset + segment.stringLength <= queryStringRange.location)
      return;
    
    // Get relative positions to current semgnet
    NSRange segmentRelativeStringRange = queryStringRange;
    if (segmentRelativeStringRange.location >= stringOffset)
    {
      segmentRelativeStringRange.location -= stringOffset;
    }
    else
    {
      segmentRelativeStringRange.length -= stringOffset - segmentRelativeStringRange.location;
      segmentRelativeStringRange.location = 0;
    }
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
      
      stringEnd = stringOffset + NSMaxRange(lineStringRange);
      
      if (limit)
        *stop = *innserStop = YES;
    }];
    
    // Exit if finished
    if (stringEnd >= NSMaxRange(queryStringRange))
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
      NSUInteger positionLine = [self _renderedLineIndexFromPosition:position graphicalOffset:&positionX];
      
      // If offset will move outsite rendered text line range, return
      if (offset < 0 && -offset > (NSInteger)positionLine)
        break;
      
      // Look for new position
      NSUInteger requestPosition = [self _positionFromRenderedLineAtIndex:(positionLine + offset) graphicalOffset:positionX];
      
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

@end
