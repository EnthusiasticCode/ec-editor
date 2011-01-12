//
//  CSEditorView.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

//- (NSDictionary *)markedTextStyle
//{
//    return [NSDictionary dictionaryWithObjectsAndKeys:[UIColor yellowColor], UITextInputTextBackgroundColorKey, [UIColor blackColor], UITextInputTextColorKey, [UIFont fontWithName:@"Helvetica" size:32.0], UITextInputTextFontKey, nil];
//}


#import "CSEditorView.h"
#import "UIKit/UIKit.h"


@implementation CSEditorView

@synthesize markedTextStyle;

@synthesize text=_text;
@synthesize inputDelegate=_inputDelegate;

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

-(id)init
{
    self = [super init];
    if (self) {
        _text = [[NSMutableAttributedString alloc] initWithString:@"Testing..."];
    }
    return self;
}

- (void)dealloc
{
    [_text release];
    [super dealloc];
}

- (UIView *)textInputView
{
    return self;
}

- (id<UITextInputTokenizer>)tokenizer
{
    if (!_tokenizer)
    {
        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    }
    return _tokenizer;
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    NSLog(@"tap");
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    } else {
        [self.inputDelegate selectionWillChange:self];
        
        NSInteger index = [(IndexedPosition *)[self closestPositionToPoint:[tap locationInView:self]] index];
        _markedNSRange = NSMakeRange(NSNotFound, 0);
        _selectedNSRange = NSMakeRange(index, 0);
        
        [self.inputDelegate selectionDidChange:self];
    }
}

- (UITextRange *)selectedTextRange {
    return [IndexedRange rangeWithNSRange:_selectedNSRange];
}

- (UITextRange *)markedTextRange {
    return [IndexedRange rangeWithNSRange:_markedNSRange];
}

- (void)setSelectedTextRange:(UITextRange *)range
{
    IndexedRange *r = (IndexedRange *)range;
    _selectedNSRange = r.range;
}

- (void)setMarkedText:(NSString *)markedText selectedRange:(NSRange)selectedRange
{    
    if (_markedNSRange.location != NSNotFound) {
        if (!markedText) markedText = @"";
        [_text replaceCharactersInRange:_markedNSRange withString:markedText];
        _markedNSRange.length = markedText.length;
    } else if (_selectedNSRange.length > 0) {
        [_text replaceCharactersInRange:_selectedNSRange withString:markedText];
        _markedNSRange.location = _selectedNSRange.location;
        _markedNSRange.length = markedText.length;
    } else {
        [[_text mutableString] insertString:markedText atIndex:_selectedNSRange.location];
        _markedNSRange.location = _selectedNSRange.location;
        _markedNSRange.length = markedText.length;
    }
    _selectedNSRange = NSMakeRange(selectedRange.location + _markedNSRange.location, selectedRange.length);
}

- (void)unmarkText
{
    _markedNSRange = NSMakeRange(NSNotFound, 0);
}

- (BOOL)hasText
{
    if (_text.length > 0) {
        return YES;
    }
    return NO;
}

- (void)insertText:(NSString *)text
{
    if (_markedNSRange.location != NSNotFound) {
        [_text replaceCharactersInRange:_markedNSRange withString:text];
        _selectedNSRange.location = _markedNSRange.location + text.length;
        _selectedNSRange.length = 0;
        _markedNSRange = NSMakeRange(NSNotFound, 0);
    } else if (_selectedNSRange.length > 0) {
        [_text replaceCharactersInRange:_selectedNSRange withString:text];
        _selectedNSRange.length = 0;
        _selectedNSRange.location += text.length;
    } else {
        [[_text mutableString] insertString:text atIndex:_selectedNSRange.location];
        _selectedNSRange.location += text.length;
    }

    [self setNeedsDisplay];
}

- (void)deleteBackward
{
    if (![self hasText]) return;
    if (_markedNSRange.location != NSNotFound) {
        [_text deleteCharactersInRange:_markedNSRange];
        _selectedNSRange.location = _markedNSRange.location;
        _selectedNSRange.length = 0;
        _markedNSRange = NSMakeRange(NSNotFound, 0);
    } else if (_selectedNSRange.length > 0) {
        [_text deleteCharactersInRange:_selectedNSRange];
        _selectedNSRange.length = 0;
    } else if (_selectedNSRange.location == 0) {
    } else {
        NSLog(@"Backspace");
        _selectedNSRange.location--;
        _selectedNSRange.length = 1;
        [_text deleteCharactersInRange:_selectedNSRange];
        _selectedNSRange.length = 0;
    }
    
    [self setNeedsDisplay];
}

- (UITextPosition *)beginningOfDocument
{
    return [IndexedPosition positionWithIndex:0];
}

- (UITextPosition *)endOfDocument
{
    return [IndexedPosition positionWithIndex:[_text length]];
}

- (NSString *)textInRange:(UITextRange *)range
{
    IndexedRange *r = (IndexedRange *)range;
    return ([[_text mutableString] substringWithRange:r.range]);
}

- (CGRect)firstRectForRange:(UITextRange *)textRange
{
    NSRange range = [(IndexedRange *)textRange range];
    int index = range.location;
    NSArray *lines = (NSArray *) CTFrameGetLines(_frame);
    for (int i = 0; i < [lines count]; i++) {
        CTLineRef line = (CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        int localIndex = index - lineRange.location;
        if (localIndex >= 0 && localIndex < lineRange.length) {
            int finalIndex = MIN(lineRange.location + lineRange.length, range.location + range.length);
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGFloat xEnd = CTLineGetOffsetForStringIndex(line, finalIndex, NULL);
            CGPoint origin;
            CTFrameGetLineOrigins(_frame, CFRangeMake(i, 0), &origin);
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
            return CGRectMake(xStart, origin.y - descent, xEnd - xStart, ascent + descent);
        }
    }
    return CGRectNull;
}

- (CGRect)caretRectForPosition:(UITextPosition *)textPosition
{
    int index = [(IndexedPosition *)textPosition index] ;
    NSArray *lines = (NSArray *) CTFrameGetLines(_frame);
    for (int i = 0; i < [lines count]; i++) {
        CTLineRef line = (CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        int localIndex = index - lineRange.location;
        if (localIndex >= 0 && localIndex < lineRange.length) {
            CGFloat xStart = CTLineGetOffsetForStringIndex(line, index, NULL);
            CGPoint origin;
            CTFrameGetLineOrigins(_frame, CFRangeMake(i, 0), &origin);
            CGFloat ascent, descent;
            CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
            
            return CGRectMake(xStart, origin.y - descent, 1, ascent + descent);
        }
    }
    return CGRectNull;
}

- (NSInteger)closestIndexToPoint:(CGPoint)point
{
    NSArray *lines = (NSArray *) CTFrameGetLines(_frame);
    CGPoint origins[lines.count];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, lines.count), origins);
    
    for (int i = 0; i < lines.count; i++) {
        if (point.y > origins[i].y) {
            CTLineRef line = (CTLineRef) [lines objectAtIndex:i];
            return CTLineGetStringIndexForPosition(line, point);
        }
    }
    return  _text.length;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    NSInteger index = [self closestIndexToPoint:point];
    return [IndexedPosition positionWithIndex:(NSUInteger)index];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point withinRange:(UITextRange *)range
{
    NSInteger index = [self closestIndexToPoint:point];
    return [IndexedPosition positionWithIndex:(NSUInteger)index];
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    NSInteger loc = [self closestIndexToPoint:point];
    if (loc == _text.length) loc--;
    return [IndexedRange rangeWithNSRange:NSMakeRange(loc, 1)];
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)text
{
    IndexedRange *r = (IndexedRange *)range;
    if ((r.range.location + r.range.length) <= _selectedNSRange.location) {
        _selectedNSRange.location -= (r.range.length - text.length);
    } else if (r.range.location < _selectedNSRange.location) {
        // TODO: Need to also deal with overlapping ranges.
    }
    [_text replaceCharactersInRange:r.range withString:text];
}

- (NSComparisonResult)comparePosition:(UITextPosition *)position toPosition:(UITextPosition *)other
{
    NSInteger positionIndex = [(IndexedPosition *)position index];
    NSInteger otherIndex = [(IndexedPosition *)other index];
    
    if (positionIndex < otherIndex)
        return NSOrderedAscending;
    else if (positionIndex == otherIndex)
        return NSOrderedSame;
    else
        return NSOrderedDescending;
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position offset:(NSInteger)offset
{
    IndexedPosition *pos = (IndexedPosition *)position;
    NSInteger end = pos.index + offset;
    if (end > _text.length || end < 0)
        return nil;
    return [IndexedPosition positionWithIndex:end];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction offset:(NSInteger)offset
{
    NSInteger end = [(IndexedPosition *)position index];
    switch (direction)
    {
        case UITextLayoutDirectionDown:
        case UITextLayoutDirectionRight:
            end += offset;
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            end -= offset;
            break;
    }
    if (end > _text.length || end < 0)
        return nil;
    return [IndexedPosition positionWithIndex:end];
}

- (NSInteger)offsetFromPosition:(UITextPosition *)from toPosition:(UITextPosition *)toPosition
{
    IndexedPosition *f = (IndexedPosition *)from;
    IndexedPosition *t = (IndexedPosition *)toPosition;
    return (t.index - f.index);
}

- (UITextRange *)textRangeFromPosition:(UITextPosition *)fromPosition toPosition:(UITextPosition *)toPosition
{
    IndexedPosition *from = (IndexedPosition *)fromPosition;
    IndexedPosition *to = (IndexedPosition *)toPosition;
    NSRange range = NSMakeRange(MIN(from.index, to.index), ABS(to.index - from.index));
    return [IndexedRange rangeWithNSRange:range];
}

- (void)setBaseWritingDirection:(UITextWritingDirection)writingDirection forRange:(UITextRange *)range
{
    
}

- (UITextWritingDirection)baseWritingDirectionForPosition:(UITextPosition *)position inDirection:(UITextStorageDirection)direction
{
    return UITextWritingDirectionLeftToRight;
}

- (UITextPosition *)positionWithinRange:(UITextRange *)range farthestInDirection:(UITextLayoutDirection)direction
{
    switch (direction)
    {
        case UITextLayoutDirectionDown:
        case UITextLayoutDirectionRight:
            return [IndexedPosition positionWithIndex:0];
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            return [IndexedPosition positionWithIndex:_text.length];
            break;
    }
    return nil;    
}

- (UITextRange *)characterRangeByExtendingPosition:(UITextPosition *)position inDirection:(UITextLayoutDirection)direction
{
    NSInteger index = [(IndexedPosition *)position index];
    switch (direction)
    {
        case UITextLayoutDirectionDown:
        case UITextLayoutDirectionRight:
            return [IndexedRange rangeWithNSRange:NSMakeRange(index, _text.length - index)];
            break;
        case UITextLayoutDirectionUp:
        case UITextLayoutDirectionLeft:
            return [IndexedRange rangeWithNSRange:NSMakeRange(0, index)];
            break;
    }
    return nil;
}

- (void)drawRect:(CGRect)rect
{
    // set up the font used for the text
    CTFontRef font = CTFontCreateWithName(CFSTR("Helvetica-Mono"), 32.0, NULL);

    // set up the CG context, flipping coordinates (0, 0) to bottom-left
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
    
    // blank out the background
    [[UIColor whiteColor] setFill];
    UIBezierPath *background = [UIBezierPath bezierPathWithRect:[self bounds]];
    [background fill];
    
    [_text addAttribute:(id)kCTFontAttributeName value:(id)font range:NSMakeRange(0, _text.length)];
        
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) _text);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, [self bounds]);
    
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(frame, context);
    
    // clean up CF refs
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(font);
}

@end
