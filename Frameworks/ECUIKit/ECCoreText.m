//
//  ECCoreText.m
//  ECUIKit
//
//  Created by Nicola Peduzzi on 23/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCoreText.h"
#import <Foundation/Foundation.h>


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
        ++closest;
    
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
            --result;
    }
    
    free(origins);
    return result;
}

CGRect ECCTFrameGetUsedRect(CTFrameRef frame, _Bool constrainedWidth)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    if (lineCount == 0)
        return CGRectNull;
    
    CGPoint lineOrigins[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, lineCount), lineOrigins);
    
    CGFloat minX = CGFLOAT_MAX, minY = CGFLOAT_MAX;
    CGFloat maxX = CGFLOAT_MIN, maxY = CGFLOAT_MIN;
    
    for (CFIndex lineIndex = 0; lineIndex < lineCount; lineIndex++) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        CGFloat ascent, descent;
        double width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        
        CGPoint lineOrigin = lineOrigins[lineIndex];
        
        minX = MIN(minX, constrainedWidth ? lineOrigin.x : 0);
        
        CGFloat thisMaxX = constrainedWidth ? lineOrigin.x + width : width;
        maxX = MAX(maxX, thisMaxX);
        
        minY = MIN(minY, lineOrigins[lineIndex].y - descent);
        maxY = MAX(maxY, lineOrigins[lineIndex].y + ascent);
    }
    
    CGRect result = CGRectMake(minX, minY, MAX(0, maxX - minX), MAX(0, maxY - minY));
    return result;
}

void ECCTFrameEnumerateLinesWithBlock(CTFrameRef frame, lineElementBlock block)
{
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex linesCount = CFArrayGetCount(lines);
    _Bool stop = NO;
    for (CFIndex i = 0; i < linesCount; ++i)
    {
        block((CTLineRef)CFArrayGetValueAtIndex(lines, i), i, &stop);
        if (stop)
            break;
    }
}

CFIndex ECCTFrameArrayFillFramesUpThroughStringIndex(CFMutableArrayRef frames, CFIndex stringIndex, CTFramesetterRef framesetter, CGPathRef path, _Bool fillLastFrame, _Bool force)
{
    // TODO make thread safe
    CTFrameRef frame;
    CFRange frameStringRange = CFRangeMake(0, 0);
    CFIndex framesCount = CFArrayGetCount(frames);
    if (force)
    {
        CFArrayRemoveAllValues(frames);
    }
    else for (CFIndex i = 0; i < framesCount; ++i)
    {
        frame = CFArrayGetValueAtIndex(frames, i);
        frameStringRange = CTFrameGetStringRange(frame);
        if (frameStringRange.location > stringIndex)
            return -1;
        if (stringIndex < frameStringRange.location + frameStringRange.length) 
            return i;
    }
    // Calculate string range to render
    if (frameStringRange.length)
    {
        frameStringRange.location += frameStringRange.length;
        frameStringRange.length = fillLastFrame ? 0 : stringIndex - frameStringRange.location;
    }
    // Check if not already present in existing frames
    while (stringIndex >= frameStringRange.location)
    {
        frame = CTFramesetterCreateFrame(framesetter, frameStringRange, path, NULL);
        if (!frame)
            return -1;
        frameStringRange = CTFrameGetStringRange(frame);
        if (frameStringRange.location == 0 && frameStringRange.length == 0)
        {
            CFRelease(frame);
            return -1;
        }
        frameStringRange.location += frameStringRange.length;
        frameStringRange.length = fillLastFrame ? 0 : stringIndex - frameStringRange.location;
        CFArrayAppendValue(frames, frame);
        CFRelease(frame);
    }
    return CFArrayGetCount(frames) - 1;
}

CTFrameRef ECCTFrameArrayGetFrameContainingStringIndex(CFArrayRef frames, CFIndex stringIndex)
{
    CTFrameRef frame;
    CFRange stringRange;
    CFIndex count = CFArrayGetCount(frames);
    for (CFIndex i = 0; i < count; ++i)
    {
        frame = CFArrayGetValueAtIndex(frames, i);
        stringRange = CTFrameGetStringRange(frame);
        if (stringRange.location <= stringIndex && stringRange.location + stringRange.length > stringIndex)
            return frame;
    }
    return NULL;
}