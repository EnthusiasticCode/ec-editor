//
//  ECCodeView3.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 11/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView3.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreText/CoreText.h>
#import "ECCoreText.h"

@interface ECCodeView3 () {
    // Text input support ivars
    ECTextRange *selection;
    CALayer *selectionLayer;
    NSRange markedRange;
    
    // Core text support ivars
    CTFramesetterRef _framesetter;
    NSMutableArray *frames;
}

/// Return the length of the text minus the hidden tailing new line.
@property (readonly) NSUInteger textLength;

/// Method to be used before any text modification occurs.
- (void)beforeTextChange;
- (void)afterTextChangeInRange:(UITextRange *)range;

/// Support method to set the selection and notify the input delefate.
- (void)setSelectedTextRange:(ECTextRange *)newSelection notifyDelegate:(BOOL)shouldNotify;

/// Convinience method to set the selection to an index location.
- (void)setSelectedIndex:(NSUInteger)index;

/// Helper method to set the selection starting from two points.
- (void)setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

//

@property (readonly) CTFramesetterRef framesetter;

- (void)invalidateFramesetter;

@property (nonatomic) CGRect frameRect;

- (void)generateFramesUpToIndex:(NSUInteger)index;
- (void)enumerateFramesIntersectingRect:(CGRect)rect withBlock:(void(^)(CTFrameRef frame, NSUInteger idx, BOOL *stop))block;
- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void(^)(CTLineRef line, BOOL *stop))block;

- (CTFrameRef)frameContainingTextIndex:(NSUInteger)index frameOffset:(CGFloat *)offset;
//- (void)enumerateFramesContainingTextRange:(NSRange)range withBlock:(void(^)(CTFrameRef frame))block;

@end

@implementation ECCodeView3

#pragma mark -
#pragma mark Properties

@synthesize text;
@synthesize delegate;
@synthesize textInsets;
@synthesize defaultTextStyle;
@synthesize frameRect;
@synthesize autosizeHeigthToFitTextOnBoundsChange;

- (void)setDelegate:(id<ECCodeViewDelegate>)aDelegate
{
    delegate = aDelegate;
    // TODO compute if delegate responds to selectors.
}

- (void)setText:(NSMutableAttributedString *)string
{
    [self setText:string applyDefaultAttributes:NO];
}

- (void)setText:(NSMutableAttributedString *)string applyDefaultAttributes:(BOOL)defaultAttributes
{
    NSRange range = (NSRange){ 0, [string length] };
    [self beforeTextChange];
    {
        [text release];
        NSAttributedString *tailingNewLine = [[NSAttributedString alloc] initWithString:@"\n" attributes:self.defaultTextStyle.CTAttributes];
        if (string && [string length])
        {
            text = [string retain];
            [text appendAttributedString:tailingNewLine];
            if (defaultAttributes) 
            {
                [text setAttributes:self.defaultTextStyle.CTAttributes range:range];
            }
        }
        else
        {
            text = [tailingNewLine mutableCopy];
        }
        [tailingNewLine release];
    }
    [self afterTextChangeInRange:[ECTextRange textRangeWithRange:range]];
}

- (void)setBounds:(CGRect)bounds
{
    self.frameRect = bounds;
    [super setBounds:bounds];
}

- (void)setFrame:(CGRect)frame
{
    [self setFrame:frame autosizeHeightToFitText:self.autosizeHeigthToFitTextOnBoundsChange];
}

- (void)setFrame:(CGRect)frame autosizeHeightToFitText:(BOOL)autosizeHeight
{
    self.frameRect = (CGRect){ CGPointZero, frame.size };
    if (autosizeHeight) 
    {
        CFRange fitRange;
        CGRect bounds = UIEdgeInsetsInsetRect(frame, self.textInsets);
        bounds.size.height = CGFLOAT_MAX;
        CGSize fitSize = CTFramesetterSuggestFrameSizeWithConstraints(self.framesetter, (CFRange){0, 0}, NULL, bounds.size, &fitRange);
        // TODO Fix this fix
        fitSize.width = frame.size.width;
        fitSize.height = ceilf(fitSize.height + 50);
        //
        frame.size = fitSize;
    }
    [super setFrame:frame];
}

#pragma mark Private properties

- (NSUInteger)textLength
{
    NSUInteger len = [text length];
    return len ? len - 1 : 0;
}

#pragma mark -
#pragma mark UIView Methods

static void init(ECCodeView3 *self)
{
    self->frames = [NSMutableArray new];
    self.defaultTextStyle = [ECTextStyle textStyleWithName:@"Plain text" font:[UIFont fontWithName:@"Courier New" size:16.0] color:[UIColor blackColor]];
    self.textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    self->text = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:self->defaultTextStyle.CTAttributes];
}

- (void)dealloc
{
    // TODO release frames
    [frames release];
    [selection release];
    [text release];
    [self invalidateFramesetter];
    [super dealloc];
}

- (id)initWithFrame:(CGRect)frame
{
    init(self);
    self = [super initWithFrame:frame];
    if (self) {
        // TODO or textinsets are not set before setFrame
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    init(self);
    self = [super initWithCoder:coder];
    if (self) {
        // TODO or textinsets are not set before setFrame
    }
    return self;
}

#pragma mark -
#pragma mark UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // TODO should return depending on edit enabled state
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL shouldBecomeFirstResponder = [super becomeFirstResponder];
    
//    // Lazy create recognizers
//    if (!tapRecognizer && shouldBecomeFirstResponder)
//    {
//        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTap:)];
//        [self addGestureRecognizer:tapRecognizer];
//        [tapRecognizer release];
//        
//        // TODO initialize gesture recognizers
//    }
//    
//    // Activate recognizers
//    if (shouldBecomeFirstResponder)
//    {
//        focusRecognizer.enabled = NO;
//        tapRecognizer.enabled = YES;
//        //        doubleTapRecognizer.enabled = YES;
//        //        tapHoldRecognizer.enabled = YES;
//    }
    
    [self setNeedsLayout];
    
    if (selection)
        [self setNeedsDisplay];
    
    return shouldBecomeFirstResponder;   
}

- (BOOL)resignFirstResponder
{
    BOOL shouldResignFirstResponder = [super resignFirstResponder];
    
//    if (![self isFirstResponder])
//    {
//        focusRecognizer.enabled = YES;
//        tapRecognizer.enabled = NO;
//        //        doubleTapRecognizer.enabled = NO;
//        //        tapHoldRecognizer.enabled = NO;
//        
//        // TODO remove thumbs
//    }
    
    [self setNeedsLayout];
    
    // TODO clear selection layer
    if (selection)
        [self setNeedsDisplay];
    
    // TODO call delegate's endediting
    
    return shouldResignFirstResponder;
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
        insertRange = (NSRange){ textLength, 0 };
    }
    else
    {
        NSUInteger s = ((ECTextPosition*)selection.start).index;
        NSUInteger e = ((ECTextPosition*)selection.end).index;
        if (s > textLength)
            s = textLength;
        if (e > textLength)
            e = textLength;
        if (e < s)
            return;
        insertRange = (NSRange){ s, e - s };
    }
    
    // TODO check if char is space and autocomplete
    
    [self beforeTextChange];
    {
        NSAttributedString *insertText = [[NSAttributedString alloc] initWithString:aText attributes:self.defaultTextStyle.CTAttributes];
        [text replaceCharactersInRange:insertRange withAttributedString:insertText];
        [insertText release];
        [self setSelectedIndex:(insertRange.location + [aText length])];
    }    
    [self afterTextChangeInRange:[ECTextRange textRangeWithRange:insertRange]];
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
        NSRange cr = [[text string] rangeOfComposedCharacterSequenceAtIndex:s-1];
        [self beforeTextChange];
        {
            [text deleteCharactersInRange:cr];
            [self setSelectedIndex:cr.location];
        }
        [self afterTextChangeInRange:[ECTextRange textRangeWithRange:cr]];
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
    [self afterTextChangeInRange:range];
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
    }
    [self afterTextChangeInRange:[ECTextRange textRangeWithRange:replaceRange]];
    
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

        // TODO!!! chech if make sense
        CGFloat frameOffset;
        CTFrameRef frame = [self frameContainingTextIndex:pos frameOffset:&frameOffset];
        
        CFArrayRef lines = CTFrameGetLines(frame);
        CFIndex lineCount = CFArrayGetCount(lines);
        CFIndex lineIndex = ECCTFrameGetLineContainingStringIndex(frame, pos, (CFRange){0, lineCount}, NULL);
        CFIndex newIndex = lineIndex + offset;
        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
        
        if (newIndex < 0 || newIndex >= lineCount)
            return nil;
        
        if (newIndex == lineIndex)
            return position;
        
        CGFloat xPosn = CTLineGetOffsetForStringIndex(line, pos, NULL) + frameOffset;
        CGPoint origins[1];
        CTFrameGetLineOrigins(frame, (CFRange){lineIndex, 1}, origins);
        xPosn = xPosn + origins[0].x; // X-coordinate in layout space
        
        CTFrameGetLineOrigins(frame, (CFRange){newIndex, 1}, origins);
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
//    CGRect r = ECCTFrameGetBoundRectOfLinesForStringRange(self->textLayer.CTFrame, [(ECTextRange *)range CFRange]);
//    return r;
    return CGRectZero;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGFloat frameOffset;
    CTFrameRef frame = [self frameContainingTextIndex:pos frameOffset:&frameOffset];
    CGRect carretRect = ECCTFrameGetBoundRectOfLinesForStringRange(frame, (CFRange){pos, 0});
    carretRect.origin.x += frameOffset;
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
//    NSUInteger textLength = [self textLength];
//    NSUInteger index = (NSUInteger)ECCTFrameGetClosestStringIndexInRangeToPoint(self->textLayer.CTFrame, ((ECTextRange *)range).CFRange, point);
//    if (index >= textLength)
//        index = textLength;
//    return [[[ECTextPosition alloc] initWithIndex:(NSUInteger)index] autorelease];
    return nil;
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
#pragma mark Rendering and layout

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (void)layoutSubviews
{
    // Create and layout selection layer
    if (selection)
    {
        // Create selection layer
        if (!selectionLayer)
        {
            selectionLayer = [CALayer layer];
            selectionLayer.backgroundColor = [UIColor blackColor].CGColor;
            NSMutableDictionary *newActions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               [NSNull null], @"bounds",
                                               [NSNull null], @"anchorPoint",
                                               [NSNull null], @"position",
                                               nil];
            selectionLayer.actions = newActions;
            [self.layer addSublayer:selectionLayer];
        }
        
        if ([selection isEmpty] && [self isFirstResponder])
        {
            // Laying out as caret
            CGRect caretRect = [self caretRectForPosition:(ECTextPosition *)selection.start];
            CGPoint textLayerOrigin = self.bounds.origin;
            caretRect.origin.x += textLayerOrigin.x + textInsets.left;
            caretRect.origin.y += textLayerOrigin.y + textInsets.top;
            selectionLayer.frame = caretRect;
            selectionLayer.hidden = NO;
        }
        else
        {
            // TODO draw actual selection
            selectionLayer.hidden = YES;
        }
    }
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Avoid drawing tiles not beginning at x == 0
    // This should never happen because tiles should always have width == bouns width
    if (rect.origin.x)
        return;
    
//    @synchronized (frames) {
        // Draw text
        __block NSUInteger lastRenderedFrameIndex = 0;
        CGContextSaveGState(context);
        {
            CGContextScaleCTM(context, 1, -1);
            CGContextSetTextPosition(context, 0, 0);
            CGContextSetTextMatrix(context, CGAffineTransformIdentity);
            
            __block CGFloat lastWidth = 0, width, ascent, descent;
            [self enumerateFramesIntersectingRect:rect withBlock:^(CTFrameRef frame, NSUInteger idx, BOOL *stop) {
//                CGContextSaveGState(context);
                CGContextTranslateCTM(context, textInsets.left, rect.origin.y ? -rect.origin.y : -textInsets.top);
                ECCTFrameEnumerateLinesWithBlock(frame, ^(CTLineRef line, CFIndex index, _Bool *stop) {
                    width = CTLineGetTypographicBounds(line, &ascent, &descent, NULL);
                    CGContextTranslateCTM(context, -lastWidth, -ascent - descent);
                    lastWidth = width;
                    CTLineDraw(line, context);
                });
                lastRenderedFrameIndex = idx;
//                CGContextRestoreGState(context);
            }];
        }
        CGContextRestoreGState(context);
//    }
    
    // Require drawing of next frame as well
    // TODO put on a different queue?
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
//        // TODO may require locking of frames array
//        [self generateFramesUpToIndex:lastRenderedFrameIndex + 1];
//    }];
    
    // DEBUG
    [[UIColor redColor] setStroke];
    CGContextSetLineWidth(context, 4);
    CGContextStrokeRect(context, rect);
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

- (void)afterTextChangeInRange:(UITextRange *)range
{
    [text endEditing];
    
//    if (delegateHasTextChangedInRange)
//    {
//        [delegate editCodeView:self textChangedInRange:range];
//    }
    
    [self invalidateFramesetter];
    
    // TODO if needed, fix paragraph styles
    
//    if (self.needsDisplayOnTextChange)
//    {
//        [self setNeedsDisplay];
//    }
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

- (void)setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint
{
    UITextPosition *startPosition = [self closestPositionToPoint:fromPoint];
    UITextPosition *endPosition;
    if (CGPointEqualToPoint(toPoint, fromPoint))
        endPosition = startPosition;
    else
        endPosition = [self closestPositionToPoint:toPoint];
    
    ECTextRange *range = [[ECTextRange alloc] initWithStart:(ECTextPosition *)startPosition end:(ECTextPosition *)endPosition];
    
    [self setSelectedTextRange:range];
    
    [range release];
}

#pragma mark -
#pragma mark Core Text Support Methods

- (CTFramesetterRef)framesetter
{
    if (!_framesetter) 
    {
        if (_framesetter)
            CFRelease(_framesetter);
        _framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)text);
        
        // TODO!!! may need to use CF
        // TODO should remove only frames after the acutal change in text
        [frames removeAllObjects];
    }
    return _framesetter;
}

- (void)invalidateFramesetter
{
    if (_framesetter) 
    {
        CFRelease(_framesetter);
        _framesetter = NULL;
    }
}

- (void)setFrameRect:(CGRect)rect
{
    if (CGRectEqualToRect(rect, frameRect))
        return;
    
    [(CATiledLayer *)self.layer setTileSize:rect.size];
    
    CGSize size = rect.size;
    size.width -= textInsets.left + textInsets.right;
    
    frameRect = (CGRect){ rect.origin, size };
    [frames removeAllObjects];
}

- (void)generateFramesUpToIndex:(NSUInteger)index
{
    // This property call will also remove all frames if required
    CTFramesetterRef fs = self.framesetter;
    
    CTFrameRef frame;
    CFRange frameStringRange = CTFrameGetVisibleStringRange((CTFrameRef)[frames lastObject]);
    frameStringRange.location += frameStringRange.length;
    frameStringRange.length = 0;
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, frameRect);
    
    NSUInteger textLength = [text length];
    
    for (NSUInteger i = [frames count]; i < index; ++i)
    {
        // Check if no more frames are needed
        // TODO CTFrameGetVisibleStringRange(frame).length == 0 may be more desirable
        if (frameStringRange.location >= textLength)
            break;
        frame = CTFramesetterCreateFrame(fs, frameStringRange, path, NULL);
        if (!frame)
            break;
        frameStringRange.location += CTFrameGetVisibleStringRange(frame).length;
        [frames addObject:(id)frame];
        CFRelease(frame);
    }
    CGPathRelease(path);
}

- (void)enumerateFramesIntersectingRect:(CGRect)rect withBlock:(void (^)(CTFrameRef, NSUInteger, BOOL *))block
{
    NSUInteger first = rect.origin.y / frameRect.size.height;
    NSUInteger count = MAX(rect.size.height / frameRect.size.height, 1);
    
    [self generateFramesUpToIndex:(first + count)];
    
    NSUInteger framesCount = [frames count];
    BOOL stop = NO;
    while (first < framesCount && count--) 
    {
        block((CTFrameRef)[frames objectAtIndex:first], first, &stop);
        if (stop)
            break;
        ++first;
    }
}

- (void)enumerateLinesIntersectingRect:(CGRect)rect usingBlock:(void (^)(CTLineRef, BOOL *))block
{
    NSUInteger firstFrame = rect.origin.y / frameRect.size.height;
    NSUInteger countFrames = rect.size.height / frameRect.size.height + 1;
    
    [self generateFramesUpToIndex:(firstFrame + countFrames)];
    
    BOOL stop = NO;
    NSUInteger framesCount = [frames count];
    CTFrameRef frame;
    CGRect frameBounds;
    CFArrayRef lines;
    CTLineRef line;
    CFIndex lineCount;
    CGPoint *origins = NULL;
    NSUInteger originsCount = 0;
    CGFloat lineWidth, lineAscent, lineDescent;
    while (firstFrame < framesCount && countFrames--) 
    {
        frame = (CTFrameRef)[frames objectAtIndex:firstFrame];
        lines = CTFrameGetLines(frame);
        lineCount = CFArrayGetCount(lines);
        //
        if (lineCount > originsCount) 
        {
            free(origins);
            origins = malloc(sizeof(CGPoint) * lineCount);
            originsCount = lineCount;
        }
        CTFrameGetLineOrigins(frame, (CFRange){ 0, lineCount }, origins);
        //
        frameBounds = CGPathGetPathBoundingBox(CTFrameGetPath(frame));
        //
        for (CFIndex i = 0; i < lineCount; ++i) 
        {
            line = CFArrayGetValueAtIndex(lines, i);
            lineWidth = CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, NULL);
            // TODO!!! actually you need to start form the very first frame...
        }
        ++firstFrame;
    }
    free(origins);
}

- (CTFrameRef)frameContainingTextIndex:(NSUInteger)index frameOffset:(CGFloat *)offset
{
//    CFIndex i = ECCTFrameArrayFillFramesUpThroughStringIndex((CFMutableArrayRef)frames, index, self.framesetter, framePath, YES, NO);
//    CTFrameRef frame = (CTFrameRef)[frames objectAtIndex:i];
//    if (offset)
//        *offset = CGPathGetPathBoundingBox(framePath).size.height * i;
//    return frame;
    return NULL;
}

@end
