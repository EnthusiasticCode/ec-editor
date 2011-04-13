//
//  ECMutableFileRenderer.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECMutableTextFileRenderer.h"
#import <CoreText/CoreText.h>

@class FramesetterInfo;
@class FrameInfo;

#pragma mark -
#pragma mark FrameInfo

@interface FrameInfo : NSObject

/// Hold a reference to the frame connected with this info block.
/// This reference may be NULL is the frame has been released due to no use.
@property (readonly) CTFrameRef frame;

/// Rect used to render the frame. This rect should have his width equal
/// to the frameWidth property.
@property (readonly) CGRect generationRect;

/// The string range used to render the frame.
@property (readonly) CFRange generationStringRange;

/// The effective string range rendered int the frame.
@property (readonly) CFRange actualStringRange;

/// Contains the actual size of this frame. Width may be smaler than rect's
/// one and height is calculated from the top of the first line to the 
/// bottom of the last rendered one.
@property (readonly) CGSize actualSize;

/// Release the frame but keeps cached rendering informations available.
- (void)releaseFrame;

- (void)generateWithFramesetter:(CTFramesetterRef)framesetter stringRange:(CFRange)range boundRect:(CGRect)bounds;

- (void)enumerateAllLinesUsingBlock:(void(^)(CTLineRef line, CFIndex idx, BOOL *stop))block;

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, CGRect lineBounds, BOOL *stop))block;

@end

@implementation FrameInfo

@synthesize frame, generationRect, generationStringRange, actualStringRange, actualSize;

- (void)dealloc
{
    [self releaseFrame];
    [super dealloc];
}

- (void)releaseFrame
{
    if (frame) 
    {
        CFRelease(frame);
        frame = NULL;
    }
}

- (void)generateWithFramesetter:(CTFramesetterRef)framesetter stringRange:(CFRange)range boundRect:(CGRect)bounds
{
    [self releaseFrame];
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, bounds);
    
    frame = CTFramesetterCreateFrame(framesetter, range, path, NULL);
    generationRect = bounds;
    generationStringRange = range;
    actualStringRange = CTFrameGetVisibleStringRange(frame);
    
    __block CGSize accumSize = CGSizeZero;
    __block CGFloat width, ascent, descent;
    [self enumerateAllLinesUsingBlock:^(CTLineRef line, CFIndex idx, BOOL *stop) {
        width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        accumSize.width = MAX(accumSize.width, width);
        accumSize.height += ascent + descent;
    }];
    actualSize = accumSize;
    
    CGPathRelease(path);
}

- (void)enumerateAllLinesUsingBlock:(void (^)(CTLineRef, CFIndex, BOOL *))block
{
    BOOL stop = NO;
    CFArrayRef lines = CTFrameGetLines(self.frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    for (CFIndex i = 0; i < lineCount; ++i) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        block(line, i, &stop);
        if (stop) break;
    }
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(CTLineRef, CGRect, BOOL *))block
{
    // Parameters sanity check
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX);
    }
    CGFloat rectEnd = rect.origin.y + rect.size.height;
    
    BOOL stop = NO;
    CGFloat currentY = 0;
    CFArrayRef lines = CTFrameGetLines(self.frame);
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
#pragma mark FramesetterInfo

@interface FramesetterInfo : NSObject {
@private
    /// Hold a reference to the framesetter connected with this info block. 
    /// This reference may be NULL if cleaning required the framesetter to be
    /// deallocated because not used.
    CTFramesetterRef framesetter;
    
    /// The array of frames generated by this framesetter.
    NSMutableArray *frames;
    
    // TODO editing data and string attributes cache
}

@property CGSize framesPreferredSize;

/// The string range in the content text that this framesetter is handling.
@property (readonly) CFRange stringRange;

/// Get the actual rendered size of the union of the framesetter's generated
/// framses originated accordingly with previous framesetters.
@property (readonly) CGSize actualSize;

/// Indicate if the framesetter associated with this \c FramesetterInfo reuires to be generated.
@property (readonly) BOOL needsFramesetterGeneration;

/// Release the framesetter but keep cached rendering informations available.
- (void)releaseFramesetter;

/// Release any previous framesetter and generate a new one from the given string.
- (void)generateFramesetterWithString:(NSAttributedString *)string preferredFrameSize:(CGSize)size;

- (void)enumerateAllFrameInfoUsingBlock:(void(^)(FrameInfo *frameInfo, NSUInteger idx, BOOL *stop))block;

- (void)enumerateFrameInfoIntersectingRect:(CGRect)rect usingBlock:(void(^)(FrameInfo *frameInfo, CGRect relativeRect, BOOL *stop))block;

@end

@implementation FramesetterInfo

@synthesize framesPreferredSize, stringRange, actualSize;

- (id)init
{
    if ((self = [super init])) 
    {
        frames = [NSMutableArray new];
    }
    return self;
}

- (void)dealloc
{
    [self releaseFramesetter];
    [frames release];
    [super dealloc];
}

- (BOOL)needsFramesetterGeneration
{
    return framesetter == NULL;
}

- (void)releaseFramesetter
{
    if (framesetter)
    {
        CFRelease(framesetter);
        framesetter = NULL;
    }
}

- (void)generateFramesetterWithString:(NSAttributedString *)string preferredFrameSize:(CGSize)size
{
    [self releaseFramesetter];
    framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
    framesPreferredSize = size;
    
    NSUInteger stringLength = [string length];
    CFRange frameRange = stringRange = CFRangeMake(0, 0);
    CGRect frameRect = (CGRect){ CGPointZero, framesPreferredSize };
    actualSize = CGSizeZero;
    
    [frames removeAllObjects];
    FrameInfo *frameInfo;
    while (stringRange.length != stringLength) 
    {
        frameInfo = [FrameInfo new];
        [frameInfo generateWithFramesetter:framesetter stringRange:frameRange boundRect:frameRect];
        
        frameRange.location += frameInfo.actualStringRange.length;
        stringRange.length += frameInfo.actualStringRange.length;
        
        actualSize.width = MAX(actualSize.width, frameInfo.actualSize.width);
        actualSize.height += frameInfo.actualSize.height;
        
        [frames addObject:frameInfo];
        [frameInfo release];
    }
}

- (void)enumerateAllFrameInfoUsingBlock:(void (^)(FrameInfo *, NSUInteger, BOOL *))block
{
    [frames enumerateObjectsUsingBlock:block];
}

- (void)enumerateFrameInfoIntersectingRect:(CGRect)rect usingBlock:(void (^)(FrameInfo *, CGRect, BOOL *))block
{
    // Parameters sanity check
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX);
    }
    CGFloat rectEnd = rect.origin.y + rect.size.height;
    
    BOOL stop = NO;
    CGFloat currentY = 0;
    FrameInfo *lastFrameInfo = nil;
    CGRect relativeRect = rect;
    for (FrameInfo *frameInfo in frames) 
    {
        // Calculate relative block
        if (lastFrameInfo) 
        {
            relativeRect.origin.y -= lastFrameInfo.actualSize.height;
        }
        lastFrameInfo = frameInfo;
        // Check if to apply to this framesetter
        if (currentY + frameInfo.actualSize.height > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            // Generate frames if needed
            if (frameInfo.frame == NULL)
            {
                [frameInfo generateWithFramesetter:framesetter stringRange:frameInfo.generationStringRange boundRect:frameInfo.generationRect];
            }
            // Apply block
            block(frameInfo, relativeRect, &stop);
            if (stop) break;
        }
        // Advance to next frame beginning
        currentY += frameInfo.actualSize.height;
    }
}

- (void)frameInfoRequireGeneration:(FrameInfo *)frameInfo
{
    
}

@end


#pragma mark -
#pragma mark ECMutableTextFileRenderer 

@interface ECMutableTextFileRenderer () {
@private
    // TODO use a cache of frameWidth -> info dictionary
//    NSCache *widthCache;
    
    NSMutableArray *framesetters;
    
    NSAttributedString *string;
}

@property (readonly) CGSize framePreferredSize;

/// Sequentially cache all rendering informations up through the given rect by
/// generating them if not already present and keeping actual rendered frames
/// for the specified rect if keep is YES.
- (void)cacheRenderingInformationsUpThroughRect:(CGRect)rect andKeepFramesIntersectingRect:(BOOL)keep;

/// Apply the given block to all framesetters that intersect the given rect.
/// If CGRectNull is passed, all framesetters info will be enumerated.
/// Prior entering the block, the enumerator makes sure that the framesetter 
/// has been generated.
- (void)enumerateFramesetterInfoIntersectingRect:(CGRect)rect usingBlock:(void(^)(FramesetterInfo *framesetterInfo, CGRect relativeRect, BOOL *stop))block;
@end

#pragma mark -

@implementation ECMutableTextFileRenderer

#pragma mark Properties
@synthesize lazyCaching;
@synthesize framesetterStringLengthLimit;
@synthesize framePreferredHeight;
@synthesize frameWidth;

- (void)setString:(NSAttributedString *)aString
{
    [string release];
    string = [aString retain];
    
    [framesetters removeAllObjects];
    if (!lazyCaching) 
    {
//        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            [self cacheRenderingInformationsUpThroughRect:CGRectNull andKeepFramesIntersectingRect:NO];
//        }];
    }
}

- (CGSize)framePreferredSize
{
    return CGSizeMake(frameWidth, framePreferredHeight);
}

#pragma mark Initialization

- (id)init {
    if ((self = [super init])) 
    {
        framesetters = [NSMutableArray new];
        framesetterStringLengthLimit = 0;
        framePreferredHeight = 1024;
        frameWidth = 768;
    }
    return self;
}

- (void)dealloc
{
    [framesetters release];
    [super dealloc];
}

#pragma mark Rendering and cacheing

- (void)cacheRenderingInformationsUpThroughRect:(CGRect)rect andKeepFramesIntersectingRect:(BOOL)keep
{
    CGFloat keepFromY = CGFLOAT_MAX;
    CGFloat cacheUpToY = CGFLOAT_MAX;
    // If no rect specified, generate cache for all text
    if (CGRectIsEmpty(rect) || CGRectIsNull(rect)) 
    {
        keep = NO;
    }
    else
    {
        keepFromY = keep ? rect.origin.y : CGFLOAT_MAX;
        cacheUpToY = rect.origin.y + rect.size.height;
    }
    // Check for already present cache informations
    CGFloat coveredHeight = 0;
    NSUInteger lastStringIndex = 0;
    for (FramesetterInfo *framesetterInfo in framesetters) 
    {
        coveredHeight += framesetterInfo.actualSize.height;
        lastStringIndex += framesetterInfo.stringRange.length;
    }
    // Generate missing informations
    NSAttributedString *subAttributedString;
    NSUInteger stringLength = [string length];
    NSUInteger stringLengthLimit = framesetterStringLengthLimit ? framesetterStringLengthLimit : stringLength;
    while (coveredHeight < cacheUpToY && lastStringIndex < stringLength)
    {
        // Get next string piece to render
        // TODO call datasource here instead of copy string
        NSRange nextStringRange = NSMakeRange(lastStringIndex, stringLengthLimit);
        subAttributedString = [string attributedSubstringFromRange:nextStringRange];
        
        // Generate new framesetter
        FramesetterInfo *framesetterInfo = [[FramesetterInfo alloc] init];
        [framesetterInfo generateFramesetterWithString:subAttributedString preferredFrameSize:self.framePreferredSize];
        
        // Releasing all non kept frames
        __block CGFloat currentFrameY = coveredHeight;
        [framesetterInfo enumerateAllFrameInfoUsingBlock:^(FrameInfo *frameInfo, NSUInteger idx, BOOL *stop) {
            if (!keep || currentFrameY < keepFromY)
            {
                [frameInfo releaseFrame];
            }
        }];
        
        // Computing new global advancement
        coveredHeight += framesetterInfo.actualSize.height;
        lastStringIndex += framesetterInfo.stringRange.length;
        
        // TODO not keep framesetter?
        [framesetters addObject:framesetterInfo];
        [framesetterInfo release];
    }
}

- (void)enumerateFramesetterInfoIntersectingRect:(CGRect)rect usingBlock:(void (^)(FramesetterInfo *, CGRect, BOOL *))block
{
    // Just checking, cache should already be present
    [self cacheRenderingInformationsUpThroughRect:rect andKeepFramesIntersectingRect:NO];
    
    // Parameters sanity check
    if (CGRectIsNull(rect) || CGRectIsEmpty(rect)) 
    {
        rect = CGRectMake(0, 0, CGFLOAT_MAX, CGFLOAT_MAX);
    }
    CGFloat rectEnd = rect.origin.y + rect.size.height;
    
    // Search and enumerate framesetter infos
    BOOL stop = NO;
    CGFloat currentY = 0;
    FramesetterInfo *lastFramesetterInfo = nil;
    CGRect relativeRect = rect;
    for (FramesetterInfo *framesetterInfo in framesetters) 
    {
        // Calculate relative block
        if (lastFramesetterInfo) 
        {
            relativeRect.origin.y -= lastFramesetterInfo.actualSize.height;
        }
        lastFramesetterInfo = framesetterInfo;
        // Check if to apply to this framesetter
        if (currentY + framesetterInfo.actualSize.height > rect.origin.y) 
        {
            // Break if past the required rect
            if (currentY >= rectEnd)
                break;
            // Generate framesetter if needed
            if (framesetterInfo.needsFramesetterGeneration) 
            {
                // TODO call datasource here instead of copy string
                NSRange subStringRange = NSMakeRange(framesetterInfo.stringRange.location, framesetterInfo.stringRange.length);
                NSAttributedString *subString = [string attributedSubstringFromRange:subStringRange];
                [framesetterInfo generateFramesetterWithString:subString preferredFrameSize:self.framePreferredSize];
            }
            // Apply block
            block(framesetterInfo, relativeRect, &stop);
            if (stop) break;
        }
        // Advance to next framesetter beginning
        currentY += framesetterInfo.actualSize.height;
    }
}

- (CGSize)drawTextInRect:(CGRect)rect inContext:(CGContextRef)context
{
    // TODO check for rendering ok
    if (!string)
        return;
    
    if (lazyCaching) 
    {
        [self cacheRenderingInformationsUpThroughRect:rect andKeepFramesIntersectingRect:YES];
    }
    
    __block CGSize drawnSize = CGSizeZero;
    __block CGRect lastLineBounds = CGRectZero;
    [self enumerateFramesetterInfoIntersectingRect:rect usingBlock:^(FramesetterInfo *framesetterInfo, CGRect relativeRect, BOOL *stop) {
//        CGContextTranslateCTM(context, 0, -relativeRect.origin.y);
        [framesetterInfo enumerateFrameInfoIntersectingRect:relativeRect usingBlock:^(FrameInfo *frameInfo, CGRect relativeRect, BOOL *stop) {
            [frameInfo enumerateLinesIntersectingRect:relativeRect usingBlock:^(CTLineRef line, CGRect lineBounds, BOOL *stop) {
                CGContextTranslateCTM(context, 0, -lineBounds.size.height);
                CTLineDraw(line, context);
                // TODO use + or - depending on context flipped
                CGContextTranslateCTM(context, -lineBounds.size.width, 0);
                
                drawnSize.height += lineBounds.size.height;
                lastLineBounds = lineBounds;
            }];
//            [frameInfo releaseFrame];
        }];
    }];
    
    drawnSize.height -= lastLineBounds.size.height;
    return drawnSize;
}

- (CGSize)renderedTextSizeAllowGuessedResult:(BOOL)guessed
{
    if (!string)
        return CGSizeZero;
        
    if (!guessed)
        [self cacheRenderingInformationsUpThroughRect:CGRectNull andKeepFramesIntersectingRect:NO];

    // Calculate actual size from frames already cached
    NSUInteger coveredString = 0;
    CGSize renderSize = CGSizeZero, framesetterInfoSize;
    for (FramesetterInfo *framesetterInfo in framesetters) 
    {
        framesetterInfoSize = framesetterInfo.actualSize;
        renderSize.width = MAX(renderSize.width, framesetterInfoSize.width);
        renderSize.height += framesetterInfoSize.height;
        
        coveredString += framesetterInfo.stringRange.length;
    }
    
    // If not covering all content, guess rest
    NSUInteger stringLength = [string length];
    if (coveredString < stringLength) 
    {
        // TODO should guess in a lower profile fashon
        CFRange fitRange;
        NSRange remaininRange = NSMakeRange(coveredString, stringLength - coveredString);
        CTFramesetterRef remain = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)[string attributedSubstringFromRange:remaininRange]);
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(remain, (CFRange){ 0, 0 }, NULL, (CGSize){ frameWidth, CGFLOAT_MAX }, &fitRange);
        CFRelease(remain);
        
        renderSize.height += suggestedSize.height;
    }
    
    return renderSize;
}

@end
