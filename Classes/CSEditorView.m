//
//  CSEditorView.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CSEditorView.h"
#import "UIKit/UIKit.h"


@implementation CSEditorView

@synthesize markedTextStyle;

@synthesize text=_text;
@synthesize editing=_editing;
@synthesize inputDelegate=_inputDelegate;

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _text = [[NSMutableAttributedString alloc] initWithString:@""];
        [self setupCoreTextTransformationMatrix];
        [self addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"bounds"])
    {
        [object setupCoreTextTransformationMatrix];
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)setupCoreTextTransformationMatrix
{
    _coreTextTransformationMatrix = CGAffineTransformIdentity;
    _coreTextTransformationMatrix = CGAffineTransformTranslate(_coreTextTransformationMatrix, 0, self.bounds.size.height);
    _coreTextTransformationMatrix = CGAffineTransformScale(_coreTextTransformationMatrix, 1.0, -1.0);
}

- (CGPoint)applyCoreTextTransformationMatrixToPoint:(CGPoint)point
{
    return CGPointApplyAffineTransform (point, _coreTextTransformationMatrix);
}

- (void)applyCoreTextTransformationMatrixInPlaceToPoints:(CGPoint *)points withCount:(int)count
{
    for (int i = 0; i < count; i++)
    {
        points[i] = CGPointApplyAffineTransform(points[i], _coreTextTransformationMatrix);
    }
}

- (void)dealloc
{
    CFRelease(_frame);
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

- (BOOL)becomeFirstResponder
{
    if ([super becomeFirstResponder])
    {
        _editing = YES;
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL)resignFirstResponder
{
    if ([super resignFirstResponder])
    {
        _editing = NO;
        return YES;
    }
    else
    {
        return NO;
    }
}

- (void)tap:(UITapGestureRecognizer *)tap
{
    if (![self isFirstResponder]) {
        [self becomeFirstResponder];
    } else {
        [self.inputDelegate selectionWillChange:self];
        
        CGPoint translatedTapLocation = [self applyCoreTextTransformationMatrixToPoint:[tap locationInView:self]];
        NSInteger index = [self closestIndexToPoint:translatedTapLocation];
        NSLog(@"Closest index:%d",index);
        _markedNSRange = NSMakeRange(NSNotFound, 0);
        _selectedNSRange = NSMakeRange(index, 0);
        
        [self.inputDelegate selectionDidChange:self];
    }
    [self setNeedsDisplay];
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
    for (int i = 0; i < [lines count]; i++)
    {
        CTLineRef line = (CTLineRef) [lines objectAtIndex:i];
        CFRange lineRange = CTLineGetStringRange(line);
        int localIndex = index - lineRange.location;
         // TODO: once caretRectForPosition: is implemented, change <= to < to fix a bug with selections starting from the first character in the line
        if (localIndex >= 0 && localIndex <= lineRange.length)
        {
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
    // TODO: implement it properly instead of calling firstRectForRange:
    // TODO: implement different behavious depending on the selectionAffinity property
    int index = [(IndexedPosition *)textPosition index] ;
    UITextRange *textRange = [IndexedRange rangeWithNSRange:NSMakeRange(index, 0)];
    return [self firstRectForRange:textRange];
}

- (NSInteger)closestIndexToPoint:(CGPoint)point
{
    NSArray *lines = (NSArray *) CTFrameGetLines(_frame);
    CGPoint origins[lines.count];
    CTFrameGetLineOrigins(_frame, CFRangeMake(0, lines.count), origins);
    
    for (int i = 0; i < lines.count; i++) {
        NSLog(@"point.y (%f) > origins[%d].y (%f)?",point.y, i, origins[i].y);
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

    // set up the CG context for Core Text, flipping coordinates (0, 0) to bottom-left
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
	CGContextTranslateCTM(context, 0, self.bounds.size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
    
    // blank out the background
    [[UIColor whiteColor] setFill];
    UIBezierPath *background = [UIBezierPath bezierPathWithRect:[self bounds]];
    [background fill];
    
    // draw text
    [_text addAttribute:(id)kCTFontAttributeName value:(id)font range:NSMakeRange(0, _text.length)];
        
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef) _text);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, [self bounds]);
    
    _frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    CTFrameDraw(_frame, context);
    
    // draw the caret
    if (_editing)
    {
        [[UIColor blueColor] setStroke];
        UIBezierPath *caret = [UIBezierPath bezierPathWithRect:[self caretRectForPosition:[IndexedPosition positionWithIndex:_selectedNSRange.location]]];
        [caret stroke];
    }
        
    // clean up CF refs
    CFRelease(path);
    CFRelease(framesetter);
    CFRelease(font);
}

@end
