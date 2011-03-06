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
    [self invalidateContent];
}

- (void)setBounds:(CGRect)bounds
{
    [super setBounds:CGRectIntegral(bounds)];
    if (wrapped)
        [self invalidateContent];
}

#pragma mark CALayer methods

- (CATransform3D)transform
{
    CATransform3D t = CATransform3DMakeAffineTransform((CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        0, self.CTFrameSize.height
    });
    CATransform3D o = [super transform];
    if (!CATransform3DIsIdentity(o))
    {
        t = CATransform3DConcat(t, o);
    }
    return t;
}

- (CGAffineTransform)affineTransform
{
    CGAffineTransform t = (CGAffineTransform){
        self.contentsScale, 0,
        0, -self.contentsScale,
        0, self.CTFrameSize.height
    };
    CGAffineTransform o = [super affineTransform];
    if (!CGAffineTransformIsIdentity(o))
    {
        t = CGAffineTransformConcat(t, o);
    }
    return t;
}

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

    CGAffineTransform t = [self affineTransform];
    CGContextConcatCTM(context, t);
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CTFrameDraw(self.CTFrame, context);
}

#pragma mark Public methods

- (void)invalidateContent
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

CFIndex ECCoreTextLineContainingLocation(CFArrayRef lines, CFIndex location, CFRange within, CTLineRef *resultLine)
{
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

void ECCoreTextProcessRectsOfLinesInStringRange(CTFrameRef frame, CFRange range, RectBlock block)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CFIndex firstLine = ECCoreTextLineContainingLocation(lines, range.location, (CFRange){0, lineCount}, NULL);

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
        CGRect lineRect = CGRectMake(0, 0, 0, ascent + descent);
        
        if (rangeEndLocation < (NSUInteger)lineRange.location)
        {
            // Requested range ends before the beginning of this line
            break;
        }
        else if (range.location <= (NSUInteger)lineRange.location) 
        {
            // Requested range starts before this line
            // Left is line wrap
            left = 0;
            spanRange.location = (NSUInteger)lineRange.location;
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

CGRect ECCoreTextBoundRectOfLinesForStringRange(CTFrameRef frame, CFRange range)
{
    __block CGRect result = CGRectNull;
    ECCoreTextProcessRectsOfLinesInStringRange(frame, range, ^(CGRect rect) {
        result = CGRectUnion(result, rect);
    });
    return result;
}
