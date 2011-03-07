//
//  ECEditCodeView.m
//  edit
//
//  Created by Nicola Peduzzi on 07/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECEditCodeView.h"

@interface ECEditCodeView () {
@private
    ECTextRange *selection;
    NSRange markedRange;
    
    // TODO add markedtext overlay layer
}

/// Method to be used before any text modification occurs.
- (void)beforeTextChange;
- (void)afterTextChange;

/// Support method to set the selection and notify the input delefate.
- (void)setSelectedTextRange:(ECTextRange *)newSelection notifyDelegate:(BOOL)shouldNotify;

/// Convinience method to set the selection to an index location.
- (void)setSelectedIndex:(NSUInteger)index;

@end

@implementation ECEditCodeView

#pragma mark -
#pragma mark ECCodeView methods

- (NSUInteger)textLength
{
    NSUInteger len = [text length];
    return len ? len - 1 : 0;
}

- (void)setText:(NSString *)string
{
    if (!text || ![text length])
    {
        [text release];
        text = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:self.defaultTextStyle.CTAttributes];
        // TODO find a way to remove this
        self->textLayer.string = text;
    }
    
    [self beforeTextChange];
    {
        NSUInteger textLength = [self textLength];
        if (string)
        {
            [text replaceCharactersInRange:(NSRange){0, textLength} withString:string];
        }
        else if (textLength > 0)
        {
            [text deleteCharactersInRange:(NSRange){0, textLength}];
        }
    }
    [self afterTextChange];
}

#pragma mark -
#pragma mark UIKeyInput protocol

- (BOOL)hasText
{
    return [self textLength] > 0;
}

- (void)insertText:(NSString *)aText
{
    // Select insertion range
    NSUInteger textLength = [self textLength];
    NSRange insertRange;
    if (!selection)
    {
        insertRange = NSMakeRange(textLength, 0);
    }
    else
    {
        NSUInteger s = ((ECTextPosition*)selection.start).index;
        NSUInteger e = ((ECTextPosition*)selection.end).index;
        if (e > textLength || s > textLength || e < s)
            return;
        insertRange = NSMakeRange(s, e - s);
    }
    
    // TODO check if char is space and autocomplete
    
    [self beforeTextChange];
    {
        NSAttributedString *insertText = [[NSAttributedString alloc] initWithString:aText attributes:self.defaultTextStyle.CTAttributes];
        [text replaceCharactersInRange:insertRange withAttributedString:insertText];
        [insertText release];
        [self setSelectedIndex:(insertRange.location + [aText length])];
    }    
    [self afterTextChange];
}

- (void)deleteBackward
{
    ECTextRange *sel = (ECTextRange *)[self selectedTextRange];
    if (!sel)
        return;
    
    NSUInteger s = ((ECTextPosition *)sel.start).index;
    NSUInteger e = ((ECTextPosition *)sel.end).index;
    
    if (s < e)
    {
        [self replaceRange:sel withText:@""];
    }
    else if (s == 0)
    {
        return;
    }
    else
    {
        [self beforeTextChange];
        {
            NSRange cr = [[text string] rangeOfComposedCharacterSequenceAtIndex:s-1];
            [text deleteCharactersInRange:cr];
            [self setSelectedIndex:cr.location];
        }
        [self afterTextChange];
    }
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

- (UITextAutocorrectionType)autocorrectionType
{
    return UITextAutocorrectionTypeNo;
}

#pragma mark -
#pragma mark UITextInput protocol

@synthesize inputDelegate;
@synthesize tokenizer;

// TODO create a proper code tokenizer
- (id<UITextInputTokenizer>)tokenizer
{
    if (!tokenizer)
        tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    return tokenizer;
}

- (UIView *)textInputView
{
    return self;
}

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
        result = [[text string] substringWithRange:(NSRange){s, e - s}];
    
    return result;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)aText
{
    // Adjust replacing range
    if(!range || ![range isKindOfClass:[ECTextRange class]])
        return;
    
    NSUInteger s = ((ECTextPosition *)range.start).index;
    NSUInteger e = ((ECTextPosition *)range.end).index;
    if (e < s)
        return;
    
    NSUInteger textLength = [self textLength];
    if (s > textLength)
        s = textLength;
    
    [self beforeTextChange];
    {
        NSUInteger endIndex;
        NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:aText attributes:[text attributesAtIndex:s effectiveRange:NULL]];
        if (e > s)
        {
            NSRange c = [[text string] rangeOfComposedCharacterSequencesForRange:(NSRange){s, e - s}];
            if (c.location + c.length > textLength)
                c.length = textLength - c.location;
            [text replaceCharactersInRange:c withAttributedString:attributedText];
            endIndex = c.location + [attributedText length];
        }
        else
        {
            [text insertAttributedString:attributedText atIndex:s];
            endIndex = s + [attributedText length];
        }
        [attributedText release];
        [self setSelectedIndex:endIndex];
    }
    [self afterTextChange];
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
    NSRange replaceRange;
    NSUInteger textLength = [self textLength];
    
    if (markedRange.length == 0)
    {
        if (selection)
        {
            replaceRange = [selection range];
        }
        else
        {
            replaceRange.location = textLength;
            replaceRange.length = 0;
        }
    }
    else
    {
        replaceRange = markedRange;
    }

    NSRange newSelectionRange;
    NSUInteger markedTextLength = [markedText length];
    [self beforeTextChange];
    {
        [text replaceCharactersInRange:replaceRange withString:markedText];
        
        // Adjust selection
        if (selectedRange.location > markedTextLength 
            || selectedRange.location + selectedRange.length > markedTextLength)
        {
            newSelectionRange = (NSRange){replaceRange.location + markedTextLength, 0};
        }
        else
        {
            newSelectionRange = (NSRange){replaceRange.location + selectedRange.location, selectedRange.length};
        }        
    }
    [self afterTextChange];
    
    [self willChangeValueForKey:@"markedTextRange"];
    ECTextRange *newSelection = [[ECTextRange alloc] initWithRange:newSelectionRange];
    [self setSelectedTextRange:newSelection notifyDelegate:NO];
    [newSelection release];
    markedRange = (NSRange){replaceRange.location, markedTextLength};
    [self didChangeValueForKey:@"markedTextRange"];
}

- (void)unmarkText
{
    if (markedRange.length == 0)
        return;
    
    // TODO needsdisplay for markedText layer.
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
        
        CFArrayRef lines = CTFrameGetLines(self->textLayer.CTFrame);
        CFIndex lineCount = CFArrayGetCount(lines);
        CFIndex lineIndex = ECCoreTextLineContainingLocation(lines, pos, (CFRange){0, lineCount}, NULL);
        CFIndex newIndex = lineIndex + offset;
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        if (newIndex < 0 || newIndex >= lineCount)
            return nil;
        
        if (newIndex == lineIndex)
            return position;
        
        CGFloat xPosn = CTLineGetOffsetForStringIndex(line, pos, NULL);
        CGPoint origins[1];
        CTFrameGetLineOrigins(self->textLayer.CTFrame, (CFRange){lineIndex, 1}, origins);
        xPosn = xPosn + origins[0].x; // X-coordinate in layout space
        
        CTFrameGetLineOrigins(self->textLayer.CTFrame, (CFRange){newIndex, 1}, origins);
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
    
    NSUInteger textLength = [self textLength];
    if (result > textLength)
        result = textLength;
    
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
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:[self textLength]] autorelease];
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

- (UITextPosition *)positionWithinRange:(UITextRange *)range 
                    farthestInDirection:(UITextLayoutDirection)direction
{
    // TODO
    abort();
}

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
    CGRect r = ECCoreTextBoundRectOfLinesForStringRange(self->textLayer.CTFrame, [(ECTextRange *)range CFRange]);
    return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = ECCoreTextBoundRectOfLinesForStringRange(self->textLayer.CTFrame, (CFRange){pos, 0});
    // TODO parametrize caret rect sizes
    carretRect.origin.x -= 1.0;
    carretRect.size.width = 2.0;
    return carretRect;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    return [self closestPositionToPoint:point withinRange:nil];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point 
                               withinRange:(UITextRange *)range
{
    // TODO update content frame if needed
    CFRange r;
    CFArrayRef lines = CTFrameGetLines(self->textLayer.CTFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CFRange lineRange;
    
    if (lineCount == 0)
        return [[[ECTextPosition alloc] initWithIndex:0] autorelease];
    
    if (range)
    {
        r = [(ECTextRange *)range CFRange];
        lineRange = ECCoreTextLineRangeOfStringRange(self->textLayer.CTFrame, r);
    }
    else
    {
        r.location = 0;
        r.length = [self textLength];
        lineRange.location = 0;
        lineRange.length = lineCount;
    }
    
    // TODO move all this to a ECCoreText function
    
    CGPoint *origins = malloc(sizeof(CGPoint) * lineRange.length);
    CTFrameGetLineOrigins(self->textLayer.CTFrame, lineRange, origins);
    CGPathRef framePath = CTFrameGetPath(self->textLayer.CTFrame);
    CGRect framePathBounds = CGPathGetPathBoundingBox(framePath);
    
    // Transform point
    point.x += framePathBounds.size.height;
    
    // Find lines containing point
    CFIndex closest = 0;
    while (closest < lineRange.length && origins[closest].y > point.y)
        closest++;
    
    if (closest >= lineRange.length)
        closest = lineRange.length - 1;
    
    NSUInteger result;
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
    
    if (x <= 0 && ECCoreTextIndexInRange(lineStringRange.location, r)) 
    {
        result = lineStringRange.location;
    }
    else if (x >= lineWidth && ECCoreTextIndexInRange(lineStringRange.location + lineStringRange.length, r)) 
    {
        result = lineStringRange.location + lineStringRange.length;
    }
    else
    {
        CFIndex lineStringIndex = CTLineGetStringIndexForPosition(line, (CGPoint){ x, y });
        if (lineStringIndex < 0 || ((NSUInteger)lineStringIndex < r.location)) 
        {
            result = r.location;
        } 
        else if (((NSUInteger)lineStringIndex - r.location) > r.length) 
        {
            result = r.location + r.length;
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
    return [[[ECTextPosition alloc] initWithIndex:result] autorelease];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    ECTextPosition *pos = (ECTextPosition *)[self closestPositionToPoint:point];
    
    NSRange r = [[text string] rangeOfComposedCharacterSequenceAtIndex:pos.index];
    
    if (r.location == NSNotFound)
        return nil;
    
    return [[[ECTextRange alloc] initWithRange:r] autorelease];
}

#pragma mark Returning Text Styling Information

- (NSDictionary *)textStylingAtPosition:(UITextPosition *)position 
                            inDirection:(UITextStorageDirection)direction
{
    ECTextPosition *pos = (ECTextPosition *)position;
    NSUInteger index = pos.index;
    
    NSDictionary *ctStyles;
    if (direction == UITextStorageDirectionBackward && index > 0)
        ctStyles = [text attributesAtIndex:index-1 effectiveRange:NULL];
    else
        ctStyles = [text attributesAtIndex:index effectiveRange:NULL];
    
    // TODO Return typingAttributes, if position is the same as the insertion point?
    
    NSMutableDictionary *uiStyles = [ctStyles mutableCopy];
    [uiStyles autorelease];
    
    CTFontRef ctFont = (CTFontRef)[ctStyles objectForKey:(id)kCTFontAttributeName];
    if (ctFont) 
    {
        CFStringRef fontName = CTFontCopyPostScriptName(ctFont);
        UIFont *uif = [UIFont fontWithName:(id)fontName size:CTFontGetSize(ctFont)];
        CFRelease(fontName);
        [uiStyles setObject:uif forKey:UITextInputTextFontKey];
    }
    
    CGColorRef cgColor = (CGColorRef)[ctStyles objectForKey:(id)kCTForegroundColorAttributeName];
    if (cgColor)
        [uiStyles setObject:[UIColor colorWithCGColor:cgColor] forKey:UITextInputTextColorKey];
    
    if (self.backgroundColor)
        [uiStyles setObject:self.backgroundColor forKey:UITextInputTextBackgroundColorKey];
    
    return uiStyles;
}

#pragma mark -
#pragma mark Private methods

- (void)beforeTextChange
{
    // TODO hide any non required subview and call setNeedsLayout
    
    // TODO setSolidCaret
    
    [self unmarkText];
    
    [inputDelegate textWillChange:self];
    
    [text beginEditing];
}

- (void)afterTextChange
{
    [text endEditing];
    
    [self setNeedsTextRendering];
    
    // TODO if needed, fix paragraph styles
    
    [self setNeedsDisplay];
}

- (void)setSelectedTextRange:(ECTextRange *)newSelection notifyDelegate:(BOOL)shouldNotify
{
    if (selection == newSelection)
        return;
    
    if (newSelection && selection && [newSelection isEqual:selection])
        return;
    
    // TODO selectionDirtyRect 
    
//    if (newSelection && (![newSelection isEmpty])) // TODO or solid caret
//        [self setNeedsDisplayInRange:newSelection];
    
    if (shouldNotify)
        [inputDelegate selectionWillChange:self];
    
    [selection release];
    selection = [newSelection retain];
    
    if (shouldNotify)
        [inputDelegate selectionDidChange:self];
    
    [self setNeedsLayout];
}

- (void)setSelectedIndex:(NSUInteger)index
{
    ECTextRange *range = [[ECTextRange alloc] initWithRange:(NSRange){index, 0}];
    [self setSelectedTextRange:range notifyDelegate:NO];
    [range release];
}

@end
