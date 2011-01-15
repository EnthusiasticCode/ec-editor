// Copyright 2010 The Omni Group.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import "OUITextLayout.h"

#import <CoreText/CTStringAttributes.h>
#import "OQDrawing.h"

#include <string.h>


CTFontRef OUIGlobalDefaultFont(void)
{
    static CTFontRef globalFont = NULL;
    if (!globalFont)
        globalFont = CTFontCreateWithName(CFSTR("Helvetica"), 12, NULL);
    return globalFont;
}

// CTFramesetterSuggestFrameSizeWithConstraints seems to be useless. It doesn't return a size that will avoid wrapping in the real frame setter. Also, it doesn't include the descender of the bottom line.
CGRect OUITextLayoutMeasureFrame(CTFrameRef frame, BOOL includeTrailingWhitespace)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    if (lineCount > 0) {
        CGPoint lineOrigins[lineCount];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, lineCount), lineOrigins);
        
        CGFloat minX, maxX, minY, maxY;
        CGFloat ascent, descent;
        double width;
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, 0);
        minX = lineOrigins[0].x;
        width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        maxX = minX + ( includeTrailingWhitespace? width : width - CTLineGetTrailingWhitespaceWidth(line));
        maxY = lineOrigins[0].y + ascent;
        minY = lineOrigins[0].y - descent;
        
        for (CFIndex lineIndex = 1; lineIndex < lineCount; lineIndex++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
            width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            CGPoint lineOrigin = lineOrigins[lineIndex];
            if (lineOrigin.x < minX)
                minX = lineOrigin.x;
            if (lineOrigin.x + width > maxX) {
                if (!includeTrailingWhitespace)
                    width -= CTLineGetTrailingWhitespaceWidth(line);
                CGFloat thisMaxX = lineOrigin.x + width;
                if (thisMaxX > maxX)
                    maxX = thisMaxX;
            }
            
            if (lineOrigins[lineIndex].y + ascent > maxY)
                maxY = lineOrigins[lineIndex].y + ascent;
            if (lineOrigins[lineIndex].y - descent < minY)
                minY = lineOrigins[lineIndex].y - descent;
        }

        return (CGRect){
            { minX, minY },
            { MAX(0, maxX - minX), MAX(0, maxY - minY) }
        };
    } else {
        return CGRectNull;
    }
}

CGPoint OUITextLayoutOrigin(CGRect typographicFrame, UIEdgeInsets textInset, // in text coordinates
                            CGRect bounds, // view rect we want to draw in
                            CGFloat scale) // scale factor from text to view
{
    // We don't offset the layoutOrigin for a non-zero bounds origin.
    if (!CGPointEqualToPoint(bounds.origin, CGPointZero))
    {
        NSLog(@"OUITextLayoutOrigin: only if bounds.origin is zero"); // Don't bother with this ever so slightly more complicated transform unless we need to.
        return CGPointMake(0, 0);
    }
    
    CGPoint layoutOrigin;
    
    // And compute the layout origin, pinning the text to the *top* of the view
    layoutOrigin.x = - typographicFrame.origin.x;
    layoutOrigin.y = CGRectGetMaxY(bounds) / scale - CGRectGetMaxY(typographicFrame);
    layoutOrigin.x += textInset.left;
    layoutOrigin.y -= textInset.top;
    
    // Lessens jumpiness when transitioning between a OUITextLayout for display and OUIEditableFrame for editing. But, it seems weird to be rounding in text space instead of view space. Maybe works out since we end up having to draw at pixel-side for UIKit backing store anyway. Still some room for improvement here.
//    layoutOrigin.x = floor(layoutOrigin.x);
//    layoutOrigin.y = floor(layoutOrigin.y);
    
    return layoutOrigin;
}

void OUITextLayoutDrawFrame(CGContextRef ctx, CTFrameRef frame, CGRect bounds, CGPoint layoutOrigin)
{
    CGContextSetTextPosition(ctx, 0, 0);
    CGContextSetTextMatrix(ctx, CGAffineTransformIdentity);
    
    CGContextTranslateCTM(ctx, layoutOrigin.x, layoutOrigin.y);
        
    CTFrameDraw(frame, ctx);

    CGContextTranslateCTM(ctx, -layoutOrigin.x, -layoutOrigin.y);
}

/* Fix up paragraph styles. We want any paragraph to have only one paragraph style associated with it. */
void OUITextLayoutFixupParagraphStyles(NSMutableAttributedString *content)
{
    NSUInteger contentLength = [content length];
    NSUInteger cursor = 0;
    NSString *paragraphStyle = (id)kCTParagraphStyleAttributeName;
    
    while (cursor < contentLength) {
        NSRange styleRange;
        [content attribute:paragraphStyle atIndex:cursor longestEffectiveRange:&styleRange inRange:(NSRange){cursor, contentLength-cursor}];
        if ((styleRange.location + styleRange.length) >= contentLength)
            break;
        NSUInteger paragraphStart, paragraphEnd, paragraphContentsEnd;
        [[content string] getParagraphStart:&paragraphStart end:&paragraphEnd contentsEnd:&paragraphContentsEnd forRange:(NSRange){styleRange.location + styleRange.length - 1, 1}];
        if (paragraphEnd > styleRange.location + styleRange.length) {
            /* The containing paragraph extends past the end of this run of paragraph styles, so we'll need to fix things up */
            
            /*
             Two heuristics.
             One: If the paragraph end has a style, apply it to the whole paragraph. This imitates the behavior of many text editors (including TextEdit) where the paragraph style behaves as if it's attached to the end-of-paragraph character.
             Two: Otherwise, use the last (non-nil) paragraph style in the range. (Not sure if this is best, but it's easy. Maybe we should do a majority-rules kind of thing? But most of the time, whoever modifies the paragraph should ensure that the styles are reasonably handled by heuristic one.)
             If these both fail, we'll fall through to the default styles case, below.
             */
            
            NSRange paragraphRange = (NSRange){paragraphStart, paragraphEnd-paragraphStart};
            NSRange eolStyleRange;
            id eolStyle, applyStyle;
            if (paragraphContentsEnd > paragraphEnd) {
                eolStyle = [content attribute:paragraphStyle atIndex:paragraphContentsEnd longestEffectiveRange:&eolStyleRange inRange:paragraphRange];
            } else {
                /* This is a little obtuse, but if there's no EOL marker, we can just get the style of the last character, and we end up implementing heuristic two */
                eolStyle = [content attribute:paragraphStyle atIndex:paragraphContentsEnd-1 longestEffectiveRange:&eolStyleRange inRange:paragraphRange];
            }
            
            if (eolStyle) {
                applyStyle = eolStyle;
            } else {
                /* Since we got nil, and asked for the longest effective range, we know the character right before the returned effective range must have a non-nil style */
                applyStyle = [content attribute:paragraphStyle atIndex:eolStyleRange.location - 1 effectiveRange:NULL];
            }
            
            /* Apply this to the whole paragraph */
            [content addAttribute:paragraphStyle value:applyStyle range:paragraphRange];
            cursor = paragraphEnd;
        } else {
            /* No fixup needed: the style boundary is also a paragraph boundary. */
            cursor = styleRange.location + styleRange.length;
        }
    }
}

