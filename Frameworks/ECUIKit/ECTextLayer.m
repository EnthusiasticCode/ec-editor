//
//  ECTextLayer.m
//  edit
//
//  Created by Nicola Peduzzi on 05/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTextLayer.h"

@interface ECTextLayer () {
@private
    BOOL CTFrameInvalid;
}

@property (nonatomic, readonly) CTFramesetterRef CTFrameSetter;

@end

#pragma mark -

@implementation ECTextLayer

#pragma mark Properties

@synthesize string;
@synthesize wrapped;

- (CFArrayRef)CTLines
{
    return CTFrameGetLines(self.CTFrame);
}

- (void)setString:(NSAttributedString *)aString
{
    string = aString;
    [self setNeedsCTFrameRendering];
}


#pragma mark CALayer methods

- (BOOL)isGeometryFlipped
{
    return YES;
}

- (CGSize)preferredFrameSize
{
    CGRect bounds = self.bounds;
    bounds.size = self.CTFrameSize;
    bounds = [self.superlayer convertRect:bounds fromLayer:self];
    return bounds.size;
}

 - (void)drawInContext:(CGContextRef)context
{
    CGContextSetFillColorWithColor(context, self.backgroundColor);
    CGContextFillRect(context, self.bounds);

    // TODO concat custom transform?
    CGContextConcatCTM(context, (CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        0, self.bounds.size.height
    });
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(self.CTFrame, context);
}

- (void)layoutSublayers
{
    for (CALayer *layer in self.sublayers) {
        layer.frame = self.bounds;
    }
}

- (id<CAAction>)actionForKey:(NSString *)event
{
    return nil;
}

#pragma mark Public methods

- (void)setNeedsCTFrameRendering
{
    CTFrameInvalid = YES;
    [self setNeedsDisplay];
}

- (CGSize)sizeThatFits:(CGSize)size
{
    CFRange fitRange;
    size.height = CGFLOAT_MAX;
    if (!wrapped)
    {
        size.width = CGFLOAT_MAX;
    }
    size = CTFramesetterSuggestFrameSizeWithConstraints(self.CTFrameSetter, (CFRange){0, 0}, NULL, size, &fitRange);
    // TODO Fix this fix
    size.height += 2;
    return size;
}

#pragma mark Private properties

@synthesize CTFrameSetter;
@synthesize CTFrame;
@synthesize CTFrameSize;

- (CTFramesetterRef)CTFrameSetter
{
    if (string && (!CTFrameSetter || CTFrameInvalid))
    {
        if (CTFrame)
        {
            CFRelease(CTFrame);
            CTFrame = NULL;
        }
        
        if (CTFrameSetter)
        {
            CFRelease(CTFrameSetter);
            CTFrameSetter = NULL;
        }
        
        CTFrameSize = CGSizeZero;
        
        CTFrameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)string);
        
        CTFrameInvalid = NO;
    }
    return CTFrameSetter;
}

- (CTFrameRef)CTFrame
{
    if (!CTFrame)
    {
        CGSize size = self.CTFrameSize;
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, size.width, size.height));
        CTFrame = CTFramesetterCreateFrame(self.CTFrameSetter, (CFRange){0, 0}, path, NULL);
        CGPathRelease(path);
    }
    
    return CTFrame;
}

- (CGSize)CTFrameSize
{
    if (CGSizeEqualToSize(CTFrameSize, CGSizeZero))
    {
        CTFrameSize = [self sizeThatFits:self.bounds.size];
    }
    return CTFrameSize;
}

@end

#pragma mark -
#pragma mark TODO move to utility

extern inline _Bool ECCoreTextIndexInRange(CFIndex index, CFRange range)
{
    if (index < 0)
        return 0;
    return (index >= range.location && (index - range.location) < range.length);
}

CFIndex ECCTFrameGetLineContainingStringIndex(CTFrameRef frame, CFIndex location, CFRange within, CTLineRef *resultLine)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex pos = within.location;
    CFIndex endpos = within.location + within.length;
    CFIndex end = endpos;
    
    while (pos < endpos)
    {
        CFIndex i = (pos + endpos - 1) >> 1;
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        
        if (lineRange.location > location)
            endpos = i;
        else if ((lineRange.location + lineRange.length) > location)
        {
            if (resultLine) 
                *resultLine = line;
            return i;
        }
        else 
        {
            pos = i + 1;
        }
    }
    return pos < end ? kCFNotFound : pos;
}

void ECCTFrameProcessRectsOfLinesInStringRange(CTFrameRef frame, CFRange range, RectBlock block)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CGPathRef framePath = CTFrameGetPath(frame);
    CGRect framePathBunds = CGPathGetPathBoundingBox(framePath);
    
    CFIndex firstLine = ECCTFrameGetLineContainingStringIndex(frame, range.location, (CFRange){0, lineCount}, NULL);

    if (firstLine >= lineCount)
        firstLine = lineCount - 1;
    if (firstLine < 0)
        return;
    
    BOOL lastLine = NO;    
    for (CFIndex lineIndex = firstLine; lineIndex < lineCount && !lastLine; ++lineIndex) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        //
        CGFloat left, right;
        CGFloat ascent = NAN, descent = NAN;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        //
        CGPoint lineOrigin;
        CTFrameGetLineOrigins(frame, (CFRange){ lineIndex, 1 }, &lineOrigin);
        //
        NSRange spanRange;
        NSUInteger rangeEndLocation = range.location + range.length;
        //
        CGRect lineRect = CGRectMake(lineOrigin.x, framePathBunds.size.height - lineOrigin.y - ascent, 0, ascent + descent);
        
        if (rangeEndLocation < (NSUInteger)lineRange.location)
        {
            // Requested range ends before the beginning of this line
            break;
        }
        else if (range.location <= lineRange.location) 
        {
            // Requested range starts before this line
            // Left is line wrap
            left = 0;
            spanRange.location = lineRange.location;
        } 
        else 
        {
            // Reqeusted range starts inside this line
            // Left is range boundary
            left = CTLineGetOffsetForStringIndex(line, range.location, NULL);
            spanRange.location = range.location;
            lineRect.origin.x += left;
        }
        
        CGFloat trailingWhitespace = 0;
        
        CFIndex lineEndLocation = (lineRange.location + lineRange.length);
        if (ECCoreTextIndexInRange(lineEndLocation, range))
        {
            // Requested range ends after this line
            // Right is line wrap
            right = lineWidth;
            spanRange.length = lineEndLocation - spanRange.location;
            lastLine = (lineIndex + 1) >= lineCount;
            trailingWhitespace = CTLineGetTrailingWhitespaceWidth(line);
        }
        else
        {
            // Reqeuested range ends in this line
            // Right is range boundary
            right = CTLineGetOffsetForStringIndex(line, rangeEndLocation, NULL);
            spanRange.length = rangeEndLocation - spanRange.location;
            lastLine = YES;
        }
        
        lineRect.size.width = right - left + trailingWhitespace;
        
        block(lineRect);
    }
}

CGRect ECCTFrameGetBoundRectOfLinesForStringRange(CTFrameRef frame, CFRange range)
{
    __block CGRect result = CGRectNull;
    ECCTFrameProcessRectsOfLinesInStringRange(frame, range, ^(CGRect rect) {
        result = CGRectUnion(result, rect);
    });
    return result;
}

CFRange ECCTFrameGetLineRangeOfStringRange(CTFrameRef frame, CFRange range)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CFIndex queryEnd = range.location + range.length;
    
    CFIndex firstResultLine = ECCTFrameGetLineContainingStringIndex(frame, range.location, (CFRange){ 0, lineCount }, NULL);
    if (firstResultLine < 0)
        return (CFRange){ 0, 0 };
    if (firstResultLine >= lineCount)
        return (CFRange){ lineCount, 0 };
    
    CFRange lineStringRange = CTLineGetStringRange(CFArrayGetValueAtIndex(lines, firstResultLine));
    if ((lineStringRange.location + lineStringRange.length) >= queryEnd)
        return (CFRange){ firstResultLine, 1 };
    
    CFIndex lastResultLine = ECCTFrameGetLineContainingStringIndex(frame, queryEnd, (CFRange){ firstResultLine + 1, lineCount }, NULL);
    if (lastResultLine < firstResultLine)
        return (CFRange){ firstResultLine, 0 };
    if (lastResultLine >= lineCount)
        return (CFRange){ firstResultLine, lineCount - firstResultLine };
    return (CFRange){ firstResultLine, lastResultLine - firstResultLine + 1 };
}

CFIndex ECCTFrameGetClosestStringIndexInRangeToPoint(CTFrameRef frame, CFRange stringRange, CGPoint point)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CFRange frameStringRange = CTFrameGetStringRange(frame);
    
    CFRange lineRange = CFRangeMake(0, lineCount);
    if (stringRange.location == 0 && stringRange.length == 0)
    {
        stringRange = frameStringRange;
    }
    else if (stringRange.location != frameStringRange.location && stringRange.length != frameStringRange.length)
    {
        lineRange = ECCTFrameGetLineRangeOfStringRange(frame, stringRange);
    }
    
    CGPoint *origins = malloc(sizeof(CGPoint) * lineRange.length);
    CTFrameGetLineOrigins(frame, lineRange, origins);
    CGPathRef framePath = CTFrameGetPath(frame);
    CGRect framePathBounds = CGPathGetPathBoundingBox(framePath);
    
    // Transform point
    point.y = framePathBounds.size.height - point.y;
    
    // Find lines containing point
    CFIndex closest = 0;
    while (closest < lineRange.length && origins[closest].y > point.y)
        closest++;
    
    if (closest >= lineRange.length)
        closest = lineRange.length - 1;
    
    CFIndex result;
    CTLineRef line = CFArrayGetValueAtIndex(lines, lineRange.location + closest);
    CGFloat ascent = NAN;
    CGFloat descent = NAN;
    CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
    CGFloat x = point.x - origins[closest].x;
    CGFloat y = point.y - origins[closest].y;
    
    if (y < -descent)
        y = -descent;
    else if(y > ascent)
        y = ascent;
    
    CFRange lineStringRange = CTLineGetStringRange(line);
    
    if (x <= 0 && ECCoreTextIndexInRange(lineStringRange.location, stringRange)) 
    {
        result = lineStringRange.location;
    }
    else if (x >= lineWidth && ECCoreTextIndexInRange(lineStringRange.location + lineStringRange.length, stringRange)) 
    {
        result = lineStringRange.location + lineStringRange.length;
    }
    else
    {
        CFIndex lineStringIndex = CTLineGetStringIndexForPosition(line, (CGPoint){ x, y });
        if (lineStringIndex < 0 || lineStringIndex < stringRange.location) 
        {
            result = stringRange.location;
        }
        else if ((lineStringIndex - stringRange.location) > stringRange.length) 
        {
            result = stringRange.location + stringRange.length;
        }
        else 
        {
            result = lineStringIndex;
        }
    }
    
    if (closest < lineRange.length - 1)
    {
        lineRange = CTLineGetStringRange(line);
        if (result == lineRange.location + lineRange.length)
            result--;
    }
    
    free(origins);
    return result;
}
