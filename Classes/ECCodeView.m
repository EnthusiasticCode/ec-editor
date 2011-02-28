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

// TODO add to respective data structure?
static inline BOOL in_range(NSRange r, CFIndex i)
{
    if (i < 0)
        return 0;
    NSUInteger u = (NSUInteger)i;
    return (u >= r.location && ( u - r.location ) < r.length);
}

@interface ECCodeView ()

- (void)doInit;

// This method is used to indicate that the content has changed and the 
// rendering frame generated from it should be recalculated.
- (void)setNeedsContentFrame;

// A convinience method that set the selection and notify the delegate if 
// needed.
- (void)setSelectedTextRange:(ECTextRange *)selectedTextRange notifyDelegate:(BOOL)shouldNotify;

// Set the selection based on graphical points. If toPoint is nil or equal to
// fromPoint an empty selection will be set.
- (void)setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

// Convinience method to set the selection to a specific index without 
// notifying the delegate.
- (void)setSelectedIndex:(NSUInteger)index;

- (void)setNeedsDisplayInRange:(ECTextRange *)range;

- (CFIndex)lineIndexForLocation:(CFIndex)location 
                        inLines:(CFArrayRef)lines 
                    containedIn:(CFRange)range;

- (CFRange)lineRangeForTextRange:(NSRange)range;

- (void)processRectsOfLinesInRange:(NSRange)range 
                         withBlock:(void(^)(CGRect))block;

- (CGRect)rectForContentRange:(NSRange)range;

// Gesture handles
- (void)handleGestureFocus:(UIGestureRecognizer *)recognizer;
- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer;

// Return the affine transform to move and scale coordinates to the render
// space. You can specify if you want a flipping transformation.
- (CGAffineTransform)renderSpaceTransformationFlipped:(BOOL)flipped inverted:(BOOL)inverted;

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

- (void)doInit
{
    // Initialize deafult styles
    CTFontRef defaultFont = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
    defaultAttributes = [[NSDictionary dictionaryWithObject:(id)defaultFont forKey:(id)kCTFontAttributeName] retain];
    // TODO set full default coloring if textSyles == nil
    _styles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultAttributes, ECCodeStyleDefaultTextName, nil];
    
    // Set UIView properties
    self.contentMode = UIViewContentModeTopLeft;
    self.clearsContextBeforeDrawing = YES;
    self.contentInset = UIEdgeInsetsMake(10, 10, 0, 0);
    
    self.text = @"";
    
    markedRange.location = 0;
    markedRange.length = 0;
    markedRangeDirtyRect = CGRectNull;
    
    [super setContentMode:UIViewContentModeRedraw];
}

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
    { 
        [self doInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    // TODO understand why debugger doesn't always start
    if ((self = [super initWithCoder:aDecoder])) 
    {
        [self doInit];
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
    
    //
    [tokenizer release];
    
    // Recognizers
    [focusRecognizer release];
    
    [caretView release];
    [super dealloc];
}

#pragma mark CodeView methods

// see setValue:forAttribute:inRange
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range
{
    // Get attribute dictionary
    NSDictionary *attributes = [_styles objectForKey:aStyle];
    if (attributes == nil)
        attributes = defaultAttributes;
    
    NSUInteger contentLength = [content length];
    if (range.location > contentLength)
        return;
    if (range.location + range.length > contentLength)
        range.length = contentLength - range.location;
    // TODO setSolidCaret
    // TODO call beforeMutate
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
    CGContextSaveGState(context);
    CGContextConcatCTM(context, [self renderSpaceTransformationFlipped:YES inverted:NO]);
    
    // Draw core text frame
    // TODO! clip on rect
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, contentFrameOrigin.x, contentFrameOrigin.y);
    CTFrameDraw(contentFrame, context);
    CGContextRestoreGState(context);
    
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
    
//    if (selection)
//    {
//        CGRect caretRect = [self caretRectForPosition:(ECTextPosition *)selection.start];
//        [[UIColor greenColor] setFill];
//        CGContextFillRect(context, caretRect);
//    }
    
    [super drawRect:rect];
}

- (void)layoutSubviews
{
    // TODO implement custom stuff
    [super layoutSubviews];
    
    BOOL firstResponder = [self isFirstResponder];
    
    // Place cursor caret
    if (firstResponder && selection && [selection isEmpty])
    {
        CGRect caretRect = [self caretRectForPosition:(ECTextPosition *)selection.start];
        if (!caretView)
        {
            caretView = [[ECCaretView alloc] initWithFrame:caretRect];
            [self addSubview:caretView];
        }
        caretView.frame = caretRect;
        caretView.hidden = NO;
        caretView.blink = YES;
    }
    else if (caretView && !caretView.hidden)
    {
        caretView.blink = NO;
        caretView.hidden = YES;
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (!focusRecognizer)
    {
        focusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureFocus:)];
        [self addGestureRecognizer:focusRecognizer];
    }
    
    if (!content)
        [self setText:nil];
}

//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
//{	
//	if (!self.dragging) 
//    {
//		[self.nextResponder touchesEnded:touches withEvent:event]; 
//	}
//	[super touchesEnded:touches withEvent:event];
//}

#pragma mark -
#pragma mark UIResponder protocol

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL shouldBecomeFirstResponder = [super becomeFirstResponder];
    
    // Lazy create recognizers
    if (!tapRecognizer && shouldBecomeFirstResponder)
    {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTap:)];
        [self addGestureRecognizer:tapRecognizer];
        
        // TODO initialize gesture recognizers
    }
    
    // Activate recognizers
    if (shouldBecomeFirstResponder)
    {
        focusRecognizer.enabled = NO;
        tapRecognizer.enabled = YES;
        doubleTapRecognizer.enabled = YES;
        tapHoldRecognizer.enabled = YES;
    }
    
    [self setNeedsLayout];
    
    if (selection)
        [self setNeedsDisplay];
    
    return shouldBecomeFirstResponder;
}

- (BOOL)resignFirstResponder
{
    BOOL shouldResignFirstResponder = [super resignFirstResponder];
    
    if (![self isFirstResponder])
    {
        focusRecognizer.enabled = YES;
        tapRecognizer.enabled = NO;
        doubleTapRecognizer.enabled = NO;
        tapHoldRecognizer.enabled = NO;
        
        // TODO remove thumbs
    }
    
    [self setNeedsLayout];
    
    if (selection)
        [self setNeedsDisplay];
    
    // TODO call delegate's endediting
    
    return shouldResignFirstResponder;
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
            return;
        insertRange = NSMakeRange(s, e - s);
    }
    
    // TODO check if char is space and autocomplete
    
    [self unmarkText];
    
    // TODO beforeMutate
    
    // Insert text
    // TODO use styled attributes?
    NSAttributedString *insertText = [[NSAttributedString alloc] initWithString:aText attributes:defaultAttributes];
    [content replaceCharactersInRange:insertRange withAttributedString:insertText];
    [insertText release];
    
    // TODO afterMutate
    
    // Move selection
    [self setSelectedIndex:(insertRange.location + [aText length])];
    
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

    if (pos >= contentLength)
    {
        pos = contentLength;
        carretRect = [self rectForContentRange:(NSRange){pos - 1, 1}];
        carretRect.origin.x += carretRect.size.width;
    }
    else
    {
        carretRect = [self rectForContentRange:(NSRange){pos, 0}];
    }    
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
    NSRange r;
    CFArrayRef lines = CTFrameGetLines(contentFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    CFRange lineRange;
    
    if (lineCount == 0)
        return [[[ECTextPosition alloc] initWithIndex:0] autorelease];
    
    if (range)
    {
        r = [(ECTextRange *)range range];
        lineRange = [self lineRangeForTextRange:r];
    }
    else
    {
        r.location = 0;
        r.length = [content length];
        lineRange.location = 0;
        lineRange.length = lineCount;
    }
    
    CGPoint *origins = malloc(sizeof(CGPoint) * lineRange.length);
    CTFrameGetLineOrigins(contentFrame, lineRange, origins);
    
    // Transform point
    // TODO properly transform with matrix?
    point = CGPointApplyAffineTransform(point, [self renderSpaceTransformationFlipped:YES inverted:YES]);
    point.x -= contentFrameOrigin.x;
    point.y -= contentFrameOrigin.y;
    
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
    
    if (x <= 0 && in_range(r, lineStringRange.location)) 
    {
        result = lineStringRange.location;
    }
    if (x >= lineWidth && in_range(r, lineStringRange.location + lineStringRange.length)) 
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
    
    NSRange r = [[content string] rangeOfComposedCharacterSequenceAtIndex:pos.index];
    
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
        ctStyles = [content attributesAtIndex:index-1 effectiveRange:NULL];
    else
        ctStyles = [content attributesAtIndex:index effectiveRange:NULL];
    
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

- (void)setSelectedIndex:(NSUInteger)index
{
    ECTextRange *range = [[ECTextRange alloc] initWithRange:(NSRange){ index, 0}];
    [self setSelectedTextRange:range notifyDelegate:NO];
    [range release];
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
        dirtyRect = [self caretRectForPosition:(UITextPosition *)(range.start)];
    }
    else
    {
        dirtyRect = [self rectForContentRange:[range range]];
    }
    
    if (!CGRectIsEmpty(dirtyRect))
        [self setNeedsDisplayInRect:dirtyRect];
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

- (CFRange)lineRangeForTextRange:(NSRange)range
{
    CFArrayRef lines = CTFrameGetLines(contentFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CFIndex queryEnd = range.location + range.length;
    
    CFIndex firstResultLine = [self lineIndexForLocation:range.location inLines:lines containedIn:(CFRange){0, lineCount}];
    if (firstResultLine < 0)
        return (CFRange){ 0, 0 };
    if (firstResultLine >= lineCount)
        return (CFRange){ lineCount, 0 };
    
    CFRange lineStringRange = CTLineGetStringRange(CFArrayGetValueAtIndex(lines, firstResultLine));
    if ((lineStringRange.location + lineStringRange.length) >= queryEnd)
        return (CFRange){ firstResultLine, 1 };
    
    CFIndex lastResultLine =  [self lineIndexForLocation:queryEnd inLines:lines containedIn:(CFRange){firstResultLine + 1, lineCount}];
    if (lastResultLine < firstResultLine)
        return (CFRange){ firstResultLine, 0 };
    if (lastResultLine >= lineCount)
        return (CFRange){ firstResultLine, lineCount - firstResultLine };
    return (CFRange){ firstResultLine, lastResultLine - firstResultLine + 1 };
}

- (void)processRectsOfLinesInRange:(NSRange)range withBlock:(void(^)(CGRect))block
{
    // TODO update contentFrame if needed
    CFArrayRef lines = CTFrameGetLines(contentFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    if (lineCount == 0)
    {
        block(CGRectMake(0, 0, 0, 13));
        return;
    }
    
    CFIndex firstLine = [self lineIndexForLocation:range.location 
                                           inLines:lines 
                                       containedIn:(CFRange){0, lineCount}];
    if (firstLine < 0 || firstLine >= lineCount)
        return;
    
    BOOL lastLine = NO;
    CGAffineTransform transform = [self renderSpaceTransformationFlipped:YES inverted:YES];

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
        CTFrameGetLineOrigins(contentFrame, (CFRange){ lineIndex, 1 }, &lineOrigin);
        lineOrigin = CGPointApplyAffineTransform(lineOrigin, transform);
        //
        NSRange spanRange;
        NSUInteger rangeEndLocation = range.location + range.length;
        //
        CGRect lineRect = CGRectMake(0, lineOrigin.y, 0, ascent + descent);
        
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
        
        NSUInteger lineEndLocation = (NSUInteger)(lineRange.location + lineRange.length);
        if (in_range(range, lineEndLocation))
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
        
        // TODO!!! rect require additional transformations?
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

- (void)handleGestureFocus:(UIGestureRecognizer *)recognizer
{
    if (![self isFirstResponder] && [self canBecomeFirstResponder])
        [self becomeFirstResponder];
    
    CGPoint point = [recognizer locationInView:self];
    
    [self setSelectedTextFromPoint:point toPoint:point];
}

- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint point = [recognizer locationInView:self];
    
    [self setSelectedTextFromPoint:point toPoint:point];
}

- (CGAffineTransform)renderSpaceTransformationFlipped:(BOOL)flipped 
                                             inverted:(BOOL)inverted
{
    CGFloat scale = self.zoomScale;
    CGRect bounds = self.bounds;
    CGAffineTransform transform = {
        scale, 0,
        0, flipped ? -scale : scale,
        bounds.origin.x, bounds.origin.y + bounds.size.height
    };
    return inverted ? CGAffineTransformInvert(transform) : transform;
}

@end
