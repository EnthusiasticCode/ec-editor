//
//  ECCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 21/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import "ECTextPosition.h"

const NSString* ECCodeStyleDefaultTextName = @"Default";
const NSString* ECCodeStyleKeywordName = @"Keyword";
const NSString* ECCodeStyleCommentName = @"Comment";

#define RECTWALKER_LEFT_IS_RANGE_BOUNDARY  ( 00001 )
#define RECTWALKER_RIGHT_IS_RANGE_BOUNDARY ( 00002 )
#define RECTWALKER_LEFT_IS_LINE_WRAP       ( 00004 )
#define RECTWALKER_RIGHT_IS_LINE_WRAP      ( 00010 )
#define RECTWALKER_FIRST_RECT_IN_LINE      ( 00020 )
#define RECTWALKER_FIRST_LINE              ( 00040 )

@interface ECCodeView ()

// This method is used to indicate that the content has changed and the 
// rendering frame generated from it should be recalculated.
- (void)setNeedsContentFrame;

- (void)setSelectedTextRange:(ECTextRange *)selectedTextRange notifyDelegate:(BOOL)shouldNotify;

- (void)setNeedsDisplayInRange:(ECTextRange *)range;

- (CFIndex)lineIndexForLocation:(CFIndex)location 
                        inLines:(CFArrayRef)lines 
                    containedIn:(CFRange)range;

- (void)processRectsOfLinesInRange:(NSRange)range 
                         withBlock:(void(^)(CGRect))block;

- (CGRect)rectForContentRange:(NSRange)range;

@end

@implementation ECCodeView

#pragma mark Properties

@synthesize text;
- (void)setText:(NSString *)aString
{
    if (aString != text)
    {
        [text release];
        text = [aString retain];
        // Create content string with default attributes
        // A tailing new line will be kept to have a reference on used attributes
        // and possibly a non empty rect when rendering.
        if (!content || ![content length])
        {
            content = [[NSMutableAttributedString alloc] init];
        }
        // TODO call before mutate
        NSInteger len = [content length];
        if (text)
        {
            [content replaceCharactersInRange:(NSRange){0, len} withString:text];
            len = [content length];
            if (len > 1)
                [content setAttributes:defaultAttributes range:(NSRange){0, len}];
        }
        else
        {
            if (len > 1)
                [content deleteCharactersInRange:(NSRange){0, len}];
        }
        // TODO call after mutate
        //        [self unmarkText];
        // TODO set selection to end
        // TODO call delegate's textdidcahnge
        [self setNeedsContentFrame];
        [self setNeedsDisplay];
    }
}

@synthesize styles = _styles;
- (void)setStyles:(NSDictionary*)aDictionary
{
    [_styles release];
    _styles = [aDictionary mutableCopy];
    // TODO check that every style's attributes contains style backref
    NSDictionary *def = [aDictionary objectForKey:ECCodeStyleDefaultTextName];
    if (def)
    {
        [defaultAttributes release];
        defaultAttributes = [def retain];
        // TODO setup background color?
    }
    // TODO reset attributes in string
    [self setNeedsDisplay];
}

#pragma mark CodeView Initializations

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    { 
        CTFontRef defaultFont = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
        defaultAttributes = [[NSDictionary dictionaryWithObject:(id)defaultFont forKey:(id)kCTFontAttributeName] retain];
        // TODO set full default coloring if textSyles == nil
        _styles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultAttributes, ECCodeStyleDefaultTextName, nil];
        
        self.contentInset = UIEdgeInsetsMake(10, 10, 0, 0);

        markedRange.location = 0;
        markedRange.length = 0;
        markedRangeDirtyRect = CGRectNull;
        
        [super setContentMode:UIViewContentModeRedraw];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) 
    {
        // TODO call a do_init instead?
        [self init];
    }
    return self;
}

- (void)dealloc 
{
    [content release];
    if (contentFrame)
    {
        CFRelease(contentFrame);
    }
    if (frameSetter)
    {
        CFRelease(frameSetter);
    }
    self.styles = nil;
    [defaultAttributes release];
    [super dealloc];
}

#pragma mark UIView override

- (void)drawRect:(CGRect)rect 
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    
    // background
    UIColor *background = self.backgroundColor;
    if (background)
    {
        [background setFill];
        CGContextFillRect(context, rect);
    }
    
    // TODO from here: _updateLayout
    // Generate framesetter
    if (!frameSetter || contentFrameInvalid)
    {
        if (contentFrame)
        {
            CFRelease(contentFrame);
            contentFrame = NULL;
        }
        if (frameSetter)
        {
            CFRelease(frameSetter);
            frameSetter = NULL;
        }
        // TODO instead of using cache use lock?
        frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)content);
        contentFrameInvalid = NO;
    }
    
    // Render core text content frame
    UIEdgeInsets inset = self.contentInset;
    while (!contentFrame)
    {
        // Setup rendering path
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, bounds.size.width, bounds.size.height));
        contentFrame = CTFramesetterCreateFrame(frameSetter, (CFRange){0, 0}, path, NULL);
        CFRelease(path);
        
        // TODO? Calculate effective size
        //CFRange fitRange;
        //CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, (CFRange){0, 0}, NULL, bounds.size, &fitRange);
        
        // TODO? Calculating the rendering coordinate position of the text layout origin
        contentFrameOrigin = CGPointMake(inset.left, -inset.top);
        
        // TODO call delegate layoutChanged
    }
    // TODO to here: _updateLayout
    
    // TODO draw selection
    
    // Transform to flipped rendering space
    CGFloat scale = self.zoomScale;
    CGContextConcatCTM(context, (CGAffineTransform){
        scale, 0,
        0, -scale,
        bounds.origin.x, bounds.origin.y + bounds.size.height
    });    
    
    // Draw core text frame
    // TODO! clip on rect
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, contentFrameOrigin.x, contentFrameOrigin.y);
    CTFrameDraw(contentFrame, context);
    CGContextTranslateCTM(context, -contentFrameOrigin.x, -contentFrameOrigin.y);
    
    // TODO draw decorations
    
    // TESTs
//    __block CGMutablePathRef testPath = CGPathCreateMutable();
    [self processRectsOfLinesInRange:(NSRange){0, 26} withBlock:^(CGRect r) {
//        CGPathAddRect(testPath, NULL, r);
        CGContextAddRect(context, r);
    }];
    [[UIColor redColor] setStroke];
//    CGContextAddPath(context, testPath);
    CGContextStrokePath(context);
    
    [super drawRect:rect];
}

//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
//{	
//	if (!self.dragging) 
//    {
//		[self.nextResponder touchesEnded:touches withEvent:event]; 
//	}
//	[super touchesEnded:touches withEvent:event];
//}

#pragma mark CodeView methods

// see setValue:forAttribute:inRange
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range
{
    // Get attribute dictionary
    NSDictionary *attributes = [_styles objectForKey:aStyle];
    if (attributes == nil)
        attributes = defaultAttributes;
    // TODO setSolidCaret
    // TODO call beforeMutate
    NSUInteger contentLength = [content length];
    NSRange crange = [[content string] rangeOfComposedCharacterSequencesForRange:range];
    if (crange.location + crange.length > contentLength)
        crange.length = (contentLength - crange.location);
    [content setAttributes:attributes range:crange];
    // TODO call after_mutate
    [self setNeedsContentFrame];
    [self setNeedsDisplay];
}

#pragma mark CodeView utilities

- (void)setAttributes:(NSDictionary*)attributes forStyleNamed:(const NSString*)aStyle
{
    [_styles setObject:attributes forKey:aStyle];
    // TODO update every content part with this style
    //    [self setNeedsContentFrame];
    //    [self setNeedsDisplay];
}

#pragma mark -
#pragma mark UIKeyInput protocol

- (BOOL)hasText
{
    return [content length] > 0;
}

- (void)insertText:(NSString *)aText
{
    // TODO solid carret
    
    // Select insertion range
    NSUInteger contentLength = [content length];
    NSRange insertRange;
    if (selection == nil)
    {
        insertRange = NSMakeRange(contentLength, 0);
    }
    else
    {
        NSUInteger s = ((ECTextPosition*)selection.start).index;
        NSUInteger e = ((ECTextPosition*)selection.end).index;
        if (e > contentLength || s > contentLength || e < s)
        {
            return;
        }
        insertRange = NSMakeRange(s, e - s);
    }
    
    // TODO check if char is space and autocomplete
    
    // TODO unmakrText
    
    // TODO beforeMutate
    
    // Insert text
    // TODO use styled attributes?
    NSAttributedString *insertText = [[NSAttributedString alloc] initWithString:aText attributes:defaultAttributes];
    [content replaceCharactersInRange:insertRange withAttributedString:insertText];
    [insertText release];
    
    // TODO afterMutate
    
    // TODO setSelectionToIndex
    
    [self setNeedsContentFrame];
    [self setNeedsDisplay];
}

- (void)deleteBackward
{
    // TODO setsolidcarret
    
}

#pragma mark -
#pragma mark UITextInputTraits protocol

// TODO return key based on contest

- (UIKeyboardAppearance)keyboardAppearance
{
    return UIKeyboardAppearanceDefault;
}

@synthesize keyboardType;
- (UIReturnKeyType)returnKeyType
{
    return UIReturnKeyDefault;
}

- (BOOL)enablesReturnKeyAutomatically
{
    return NO;
}

- (BOOL)isSecureTextEntry
{
    return NO;
}

#pragma mark -
#pragma mark UITextInput protocol

@synthesize inputDelegate;

#pragma mark Replacing and Returning Text

- (NSString *)textInRange:(UITextRange *)range
{
    if(!range || ![range isKindOfClass:[ECTextRange class]])
        return nil;
    
    NSUInteger s = ((ECTextPosition *)range.start).index;
    NSUInteger e = ((ECTextPosition *)range.end).index;
    
    NSString *result;
    if (e <= s)
        result = @"";
    else
        result = [[content string] substringWithRange:(NSRange){s, e - s}];
    
    return result;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)aText
{
    // Adjust replacing range
    if(!range || ![range isKindOfClass:[ECTextRange class]])
        return;
    
    NSUInteger s = ((ECTextPosition *)range.start).index;
    NSUInteger e = ((ECTextPosition *)range.end).index;
    NSUInteger contentLength = [content length];
    
    if (e < s)
        return;
    if (s > contentLength)
        s = contentLength;
    
    // Prepare for contente mutation
    // TODO setSolidCaret
    
    [self unmarkText];
    
    // TODO beforeMutate
    
    // Mutate content
    // TODO style differently?
    NSUInteger endIndex;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:aText attributes:[content attributesAtIndex:s effectiveRange:NULL]];
    if (e > s)
    {
        NSRange c = [[content string] rangeOfComposedCharacterSequencesForRange:(NSRange){s, e - s}];
        if (c.location + c.length > contentLength)
            c.length = contentLength - c.location;
        [content replaceCharactersInRange:c withAttributedString:attributedText];
        endIndex = c.location + [attributedText length];
    }
    else
    {
        [content insertAttributedString:attributedText atIndex:s];
        endIndex = s + [attributedText length];
    }
    [attributedText release];
    
    // TODO afterMutate
    // TODO setSelection endIndex
    
    [self setNeedsContentFrame];
    [self setNeedsDisplay];
}

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange
{
    return selection;
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    // TODO solidCaret
    
    [self unmarkText];
    
    [self setSelectedTextRange:(ECTextRange *)selectedTextRange notifyDelegate:YES];
}

@synthesize markedTextStyle;

- (UITextRange *)markedTextRange
{
    if (markedRange.length == 0)
        return nil;
    
    return [[[ECTextRange alloc] initWithRange:markedRange] autorelease];
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{
    // TODO
}

- (void)unmarkText
{
    if (markedRange.length == 0)
        return;
    
    [self setNeedsDisplayInRect:markedRangeDirtyRect];
    [self willChangeValueForKey:@"markedTextRange"];
    markedRange.location = 0;
    markedRange.length = 0;
    [self didChangeValueForKey:@"markedTextRange"];
}

#pragma mark Computing Text Ranges and Text Positions

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition 
                            toPosition:(UITextPosition *)toPosition
{
    return [[[ECTextRange alloc] initWithStart:(ECTextPosition *)fromPosition end:(ECTextPosition *)toPosition] autorelease];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position 
                                  offset:(NSInteger)offset
{
    return [self positionFromPosition:position inDirection:UITextStorageDirectionForward offset:offset];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position 
                             inDirection:(UITextLayoutDirection)direction 
                                  offset:(NSInteger)offset
{
    if (offset == 0)
        return position;
    
    NSUInteger pos = [(ECTextPosition *)position index];
    NSUInteger result;
    
    if (direction == UITextStorageDirectionForward 
        || direction == UITextStorageDirectionBackward) 
    {
        if (direction == UITextStorageDirectionBackward)
            offset = -offset;
        
        if (offset < 0 && (NSUInteger)(-offset) >= pos)
            result = 0;
        else
            result = pos + offset;
    } 
    else if (direction == UITextLayoutDirectionLeft 
             || direction == UITextLayoutDirectionRight) 
    {
        if (direction == UITextLayoutDirectionLeft)
            offset = -offset;
        
        // TODO should move considering typography characters
        if (offset < 0 && (NSUInteger)(-offset) >= pos)
            result = 0;
        else
            result = pos + offset;
    } 
    else if (direction == UITextLayoutDirectionUp 
             || direction == UITextLayoutDirectionDown) 
    {
        if (direction == UITextLayoutDirectionUp)
            offset = -offset;
        
        CFArrayRef lines = CTFrameGetLines(contentFrame);
        CFIndex lineCount = CFArrayGetCount(lines);
        CFIndex lineIndex = [self lineIndexForLocation:pos 
                                               inLines:lines 
                                           containedIn:(CFRange){0, lineCount}];
        CFIndex newIndex = lineIndex + offset;
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        if (newIndex < 0 || newIndex >= lineCount)
            return nil;
        
        if (newIndex == lineIndex)
            return position;
        
        CGFloat xPosn = CTLineGetOffsetForStringIndex(line, pos, NULL);
        CGPoint origins[1];
        CTFrameGetLineOrigins(contentFrame, (CFRange){lineIndex, 1}, origins);
        xPosn = xPosn + origins[0].x; // X-coordinate in layout space
        
        CTFrameGetLineOrigins(contentFrame, (CFRange){newIndex, 1}, origins);
        xPosn = xPosn - origins[0].x; // X-coordinate in new line's local coordinates
        
        CFIndex newStringIndex = CTLineGetStringIndexForPosition(CFArrayGetValueAtIndex(lines, newIndex), (CGPoint){xPosn, 0});
        
        if (newStringIndex == kCFNotFound)
            return nil;
        
        if(newStringIndex < 0)
            newStringIndex = 0;
        result = newStringIndex;
    } 
    else 
    {
        // Direction unimplemented
        return position;
    }
    
    ECTextPosition *resultPosition = [[[ECTextPosition alloc] initWithIndex:result] autorelease];

    return resultPosition;
}

- (UITextPosition *)beginningOfDocument
{
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:0] autorelease];
    return p;
}

- (UITextPosition *)endOfDocument
{
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:[content length]] autorelease];
    return p;
}

#pragma mark Evaluating Text Positions

- (NSComparisonResult)comparePosition:(UITextPosition *)position 
                           toPosition:(UITextPosition *)other
{
    return [(ECTextPosition *)position compare:other];
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from 
                     toPosition:(UITextPosition *)toPosition
{
    NSUInteger si = ((ECTextPosition *)from).index;
    NSUInteger di = ((ECTextPosition *)toPosition).index;
    return (NSInteger)di - (NSInteger)si;
}

#pragma mark Determining Layout and Writing Direction

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position 
                                       inDirection:(UITextLayoutDirection)direction
{
    // TODO
    abort();
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position 
                                              inDirection:(UITextStorageDirection)direction
{
    // TODO
    abort();
}

-(void)setBaseWritingDirection:(UITextWritingDirection)writingDirection 
                      forRange:(UITextRange *)range
{
    // TODO
    abort();
}

#pragma mark Geometry and Hit-Testing Methods

- (CGRect)firstRectForRange:(UITextRange *)range
{
    // TODO update layout. NO! actually do it in processing...
    
    CGRect r = [self rectForContentRange:[(ECTextRange *)range range]];
    
    // TODO additional transformations may be needed
    return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSUInteger contentLength = [content length];
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = CGRectNull;
    // At the end of the text
    if (pos >= contentLength)
    {
        carretRect = [self rectForContentRange:(NSRange){pos - 1, pos}];
        carretRect.origin.x += carretRect.size.width - 1.0;
    }
}

#pragma mark -
#pragma mark CodeView private methods

- (void)setSelectedTextRange:(ECTextRange *)newSelection notifyDelegate:(BOOL)shouldNotify
{
    if (selection == newSelection)
        return;
    
    if (newSelection && selection && [newSelection isEqual:selection])
        return;
    
    // TODO selectionDirtyRect 
    
    if (newSelection && (![newSelection isEmpty])) // TODO or solid caret
        [self setNeedsDisplayInRange:newSelection];
    
    if (shouldNotify)
        [inputDelegate selectionWillChange:self];
    
    [selection release];
    selection = [newSelection retain];
    
    if (shouldNotify)
        [inputDelegate selectionDidChange:self];
    
    [self setNeedsLayout];
}

// TODO rethink: contentFrameInvalid should be YES if text/attr changed to recreate framesetter, 
// contentFrame should be released and set to nil when bounds changes.
- (void)setNeedsContentFrame
{
    contentFrameInvalid = YES;
    
    // TODO any content sanity check? see _didChangeContent
}


// see - (void)_setNeedsDisplayForRange:(OUEFTextRange *)range;
- (void)setNeedsDisplayInRange:(ECTextRange *)range
{
    if (!range || contentFrameInvalid || !contentFrame)
        return;
    
    CGRect dirtyRect;
    
    if ([range isEmpty])
    {
        // TODO carretRectForPosition
    }
    else
    {
        dirtyRect = [self rectForContentRange:[range range]];
    }
}

/////////////////////////////////////// TODO move in a CF helpers

- (CFIndex)lineIndexForLocation:(CFIndex)location 
                        inLines:(CFArrayRef)lines 
                    containedIn:(CFRange)range
// TODO? resultLine:(CTLineRef *)result
{
    CFIndex pos = range.location;
    CFIndex endpos = range.location + range.length;
    CFIndex end = endpos;
    
    while (pos < endpos)
    {
        CFIndex i = (pos + endpos - 1) >> 1;
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange lineRange = CTLineGetStringRange(line);
        
        if (lineRange.location > location)
            endpos = i;
        else if ((lineRange.location + lineRange.length) > location)
            // TODO? if (result) *result = line;
            return i;
        else 
            pos = i + 1;
    }
    return pos < end ? kCFNotFound : pos;
}


- (void)processRectsOfLinesInRange:(NSRange)range withBlock:(void(^)(CGRect))block
{
    // TODO update contentFrame if needed
    CFArrayRef lines = CTFrameGetLines(contentFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CFIndex firstLine = [self lineIndexForLocation:range.location 
                                           inLines:lines 
                                       containedIn:(CFRange){0, lineCount}];
    if (firstLine < 0 || firstLine >= lineCount)
        return;
    
    BOOL lastLine = NO;

    for (CFIndex lineIndex = firstLine; lineIndex < lineCount && !lastLine; ++lineIndex) 
    {
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        CFRange lineRange = CTLineGetStringRange(line);
        //
        CGFloat left, right, leftSecondary = NAN, rightSecondary = NAN;
        CGFloat ascent = NAN, descent = NAN;
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
        //
        CGPoint lineOrigin;
        CTFrameGetLineOrigins(contentFrame, (CFRange){ lineIndex, 1 }, &lineOrigin);
        //
        NSRange spanRange;
        NSUInteger rangeEndLocation = range.location + range.length;
        //
        //BOOL isFirstLine = lineIndex == firstLine;
        BOOL lineIsBoundary = NO;
        //
        CGRect lineRect = CGRectMake(contentFrameOrigin.x, contentFrameOrigin.y + lineOrigin.y - descent, 0, ascent + descent);
        
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
            left = CTLineGetOffsetForStringIndex(line, range.location, &leftSecondary);
            spanRange.location = range.location;
            lineIsBoundary = YES;
            lineRect.origin.x += lineOrigin.x;
        }

        CGFloat trailingWhitespace = 0;
        
        NSUInteger lineEndLocation = (NSUInteger)(lineRange.location + lineRange.length);
        if (range.location <= lineEndLocation
            && range.length > (lineEndLocation - range.location))
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
            right = CTLineGetOffsetForStringIndex(line, rangeEndLocation, &rightSecondary);
            spanRange.length = rangeEndLocation - spanRange.location;
            lastLine = YES;
            lineIsBoundary = YES;
        }
        
        lineRect.size.width = right - left + trailingWhitespace;
        
//        if (lineIsBoundary)
//        {
//            // Proceed caclulating rects for characters
//            CFArrayRef runs = CTLineGetGlyphRuns(line);
//            CFIndex runsCount = CFArrayGetCount(runs);
//            for (CFIndex i = 0; i < runsCount; ++i)
//            {
//                CTRunRef run = CFArrayGetValueAtIndex(runs, i);
//                CFRange runRange = CTRunGetStringRange(run);
//                CTRunStatus runStatus = CTRunGetStatus(run);
//                
//            }
//        }
        
        // TODO rect require additional transformations?
        block(lineRect);
    }
}

- (CGRect)rectForContentRange:(NSRange)range
{
    __block CGRect result = CGRectNull;
    [self processRectsOfLinesInRange:range withBlock:^(CGRect r) {
        result = CGRectUnion(result, r);
    }];
    return result;
}


@end
