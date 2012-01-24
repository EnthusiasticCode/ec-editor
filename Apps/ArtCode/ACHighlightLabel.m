//
//  ACHighlightLabel.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 05/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACHighlightLabel.h"
#import <CoreText/CoreText.h>

@implementation ACHighlightLabel

@synthesize highlightedCharacters, highlightedBackgroundColor;

- (void)setHighlightedCharacters:(NSIndexSet *)value
{
    if (value == highlightedCharacters)
        return;
    [self willChangeValueForKey:@"highlightedCharacters"];
    highlightedCharacters = value;
    [self setNeedsDisplay];
    [self didChangeValueForKey:@"highlightedCharacters"];
}

- (void)setHighlightedBackgroundColor:(UIColor *)value
{
    if (value == highlightedBackgroundColor)
        return;
    [self willChangeValueForKey:@"highlightedBackgroundColor"];
    highlightedBackgroundColor = value;
    [self setNeedsDisplay];
    [self didChangeValueForKey:@"highlightedBackgroundColor"];
}

- (NSAttributedString *)attributedText
{
    CTFontRef font = CTFontCreateWithName((__bridge CFStringRef)self.font.fontName, self.font.pointSize, NULL);
    NSAttributedString *result = [[NSAttributedString alloc] 
            initWithString:self.text 
            attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                        (__bridge id)self.textColor.CGColor, (__bridge id)kCTForegroundColorAttributeName, 
                        (__bridge id)font, (__bridge id)kCTFontAttributeName,
                        nil]];
    CFRelease(font);
    return result;
}

- (void)drawRect:(CGRect)rect
{
    if ([highlightedCharacters count] == 0)
    {
        [super drawRect:rect];
        return;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = [self bounds];
    
    [self.highlightedBackgroundColor setFill];

    
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)[self attributedText]);
    CGPathRef path = CGPathCreateWithRect(bounds, NULL);
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, [self.text length]), path, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    //ECASSERT(lineCount <= 1 && "Not designed for multiline");
    for (CFIndex i = 0; i < lineCount; ++i)
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        CGFloat ascent, descent;
        CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        [highlightedCharacters enumerateRangesInRange:NSMakeRange(lineRange.location, lineRange.length) options:0 usingBlock:^(NSRange range, BOOL *stop) {
            CGFloat startOffset = CTLineGetOffsetForStringIndex(line, range.location, NULL);
            CGFloat endOffset = CTLineGetOffsetForStringIndex(line, NSMaxRange(range), NULL);
            CGContextFillRect(context, CGRectMake(startOffset, CGRectGetMidY(bounds) - (ascent + descent) / 2.0, endOffset - startOffset, ascent + descent));
        }];
    }
    
//    CTFrameDraw(frame, context);
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    
    [super drawRect:rect];
}

@end
