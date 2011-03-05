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

const NSString *ECCodeOverlayAttributeColorName = @"OverlayColor";
const NSString *ECCodeOverlayAttributeDrawBlockName = @"OverlayDrawBlock";


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

// Return the current content length applying additional checks.
// Use this instead of [content length] to prevent undesired missbehaviour.
// TODO cache this value?
- (NSUInteger)contentLength;

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
                         withBlock:(void(^)(CGRect rct))block;

- (CGRect)rectForContentRange:(NSRange)range;

// Gesture handles
- (void)handleGestureFocus:(UIGestureRecognizer *)recognizer;
- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer;

// Return the affine transform to move and scale coordinates to the render
// space. You can specify if you want a flipping transformation.
- (CGAffineTransform)transormContentFrameFlipped:(BOOL)flipped inverted:(BOOL)inverted;

@end

@implementation ECCodeView

#pragma mark Properties

@synthesize mode;

@synthesize text;
- (NSString *)text
{
    return [[content string] substringToIndex:[self contentLength]];
}

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
            content = [[NSMutableAttributedString alloc] initWithString:@"\n" attributes:defaultAttributes];
        }
        // TODO call before mutate
        NSUInteger contentLength = [self contentLength];
        if (text)
        {
            [content replaceCharactersInRange:(NSRange){0, contentLength} withString:text];
        }
        else
        {
            if (contentLength > 0)
                [content deleteCharactersInRange:(NSRange){0, contentLength}];
        }
        // TODO call after mutate
        //        [self unmarkText];
        // TODO set selection to end
        // TODO call delegate's textdidcahnge
        [self setNeedsContentFrame];
        [self setNeedsDisplay];
    }
}

@synthesize styles;
- (void)setStyles:(NSDictionary*)aDictionary
{
    [styles release];
    styles = [aDictionary mutableCopy];
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

@synthesize selectionColor;

#pragma mark Overlay methods

@synthesize defaultOverlayDrawBlock;

- (void)setAttributes:(NSDictionary *)attributes forOverlayNamed:(NSString *)overlay
{
    [overlayStyles setObject:attributes forKey:overlay];
}

- (void)addOverlayNamed:(NSString *)overlay toRange:(NSRange)range
{
    // Only add if the given overlay style exist
    NSDictionary *o = [overlayStyles objectForKey:overlay];
    if (o)
    {
        // Get or create the mutable array or ranges
        NSMutableArray *overlayArray = [overlays objectForKey:o];
        if (!overlayArray)
        {
            overlayArray = [NSMutableArray array];
            [overlays setObject:overlayArray forKey:o];
        }
        // Add given range to array of overlays to applu
        ECTextRange *r = [[ECTextRange alloc] initWithRange:range];
        [overlayArray addObject:r];
        [r release];
    }
    
    [self setNeedsDisplay];
}

- (void)removeAllOverlays
{
    [overlays removeAllObjects];
}

- (void)removeAllOverlaysNamed:(NSString *)overlay
{
    [overlays removeObjectForKey:overlay];
}

#pragma mark CodeView Initializations

- (void)doInit
{
    // Initialize deafult styles
    CTFontRef defaultFont = CTFontCreateWithName((CFStringRef)@"Courier New", 12.0, &CGAffineTransformIdentity);
    defaultAttributes = [[NSDictionary dictionaryWithObject:(id)defaultFont forKey:(id)kCTFontAttributeName] retain];
    // TODO set full default coloring if textSyles == nil
    styles = [[NSMutableDictionary alloc] initWithObjectsAndKeys:defaultAttributes, ECCodeStyleDefaultTextName, nil];
    
    // Set UIView properties
//    self.contentMode = UIViewContentModeTopLeft;
    self.clearsContextBeforeDrawing = YES;
    
    // Set rounded corners for frame
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    
    contentFrameInset = UIEdgeInsetsMake(10, 10, 10, 10);

    markedRange.location = 0;
    markedRange.length = 0;
    markedRangeDirtyRect = CGRectNull;
    
    // Dictionary of overlay names connected to dictionary of overlay attributes
    overlayStyles = [[NSMutableDictionary alloc] init];
    // TODO default overlay styles?
    
    // Overlays is a dictionary of dictionary for an overlay named type to
    // array of ECTextRange to apply the overlay to.
    overlays = [[NSMutableDictionary alloc] init];
    
    selectionColor = [UIColor darkTextColor];
    
    // The default block used to render an overlay that doesn't have the ECCodeOverlayDrawBlockName attribute.
    self.defaultOverlayDrawBlock = ^(CGContextRef ctx, CGRect rct, NSDictionary* attr) {
        UIColor *c = (UIColor *)[attr objectForKey:ECCodeOverlayAttributeColorName];
        if (!c)
            c = [UIColor redColor];
        [c setFill];
        CGContextFillRect(ctx, rct);
    };
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
    
    [blinkAnimation release];
    
    // Overlays
    [overlays release];
    [overlayStyles release];
    self.defaultOverlayDrawBlock = nil;
    
    self.selectionColor = nil;
    [selectionHandleLeft release];
    [selectionHandleRight release];
    if (selectionPath)
        CGPathRelease(selectionPath);
    
    [super dealloc];
}

#pragma mark CodeView methods

// see setValue:forAttribute:inRange
- (void)setStyleNamed:(const NSString*)aStyle toRange:(NSRange)range
{
    // Get attribute dictionary
    NSDictionary *attributes = [styles objectForKey:aStyle];
    if (attributes == nil)
        attributes = defaultAttributes;
    
    NSUInteger contentLength = [self contentLength];
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
    [styles setObject:attributes forKey:aStyle];
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
    while (!contentFrame)
    {
        // Setup rendering path
        CGSize contentFrameSize = bounds.size;
        contentFrameSize.height = CGFLOAT_MAX;
        contentFrameSize.width -= contentFrameInset.left + contentFrameInset.right;
        
        CFRange fitRange;
        CGSize frameSize = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, (CFRange){0, 0}, NULL, contentFrameSize, &fitRange);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, frameSize.width, frameSize.height));
        
        // Render content frame
        contentFrame = CTFramesetterCreateFrame(frameSetter, (CFRange){0, 0}, path, NULL);
        CFRelease(path);
        
        // Save content frame rect
        contentFrameRect.origin = CGPointMake(contentFrameInset.left, contentFrameInset.top);
        contentFrameRect.size = frameSize;
        
        // TODO? Calculating the rendering coordinate position of the text layout origin
        
        // TODO call delegate layoutChanged
    }
    // TODO to here: _updateLayout
    
    // TODO draw selection
    
    // Transform to flipped rendering space
    CGContextSaveGState(context);
    CGContextConcatCTM(context, [self transormContentFrameFlipped:YES inverted:NO]);
    
    // Draw core text frame
    // TODO!!! clip on rect
    CGContextSetTextPosition(context, 0, 0);
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
   // CGContextTranslateCTM(context, contentFrameRect.origin.x, -contentFrameRect.origin.y);
    CTFrameDraw(contentFrame, context);
    CGContextRestoreGState(context);
    
    //  Draw overlays
    // TODO evalue if concurrent should be used only in particular case ie overlays > N
    [overlays enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id attribs, id ranges, BOOL *stop) {
        DrawOverlayBlock drawBlock = (DrawOverlayBlock)[attribs objectForKey:ECCodeOverlayAttributeDrawBlockName];
        if (!drawBlock)
            drawBlock = defaultOverlayDrawBlock;
        [(NSArray *)ranges enumerateObjectsUsingBlock:^(id range, NSUInteger idx, BOOL *stop) {
            [self processRectsOfLinesInRange:[(ECTextRange *)range range] withBlock:^(CGRect r) {
                if (CGRectIntersectsRect(r, rect))
                {
                    drawBlock(context, r, attribs);
                } // TODO else stop 
            }];
        }];
    }];
    
    [super drawRect:rect];
}

- (void)layoutSubviews
{
    // TODO implement custom stuff
    [super layoutSubviews];
    
    BOOL firstResponder = [self isFirstResponder];
    
    // Place cursor caret
    // TODO move to layoutOverlays
    if (firstResponder && selection)
    {
        if (!blinkAnimation)
        {
            blinkAnimation = [[CABasicAnimation animationWithKeyPath:@"opacity"] retain];
            blinkAnimation.duration = 0.5;
            blinkAnimation.repeatCount = CGFLOAT_MAX;
            blinkAnimation.autoreverses = YES;
            blinkAnimation.fromValue = [NSNumber numberWithFloat:1.0];
            blinkAnimation.toValue = [NSNumber numberWithFloat:0.0];    
        }
        
        if (!selectionLayer)
        {
            selectionLayer = [CALayer layer];
            // FIX only the view's layer can have self as delegate, one should use a proxy
//            selectionLayer.delegate = self;
            selectionLayer.opaque = NO;
            selectionLayer.cornerRadius = 1.0;
            selectionLayer.needsDisplayOnBoundsChange = YES;
            [self.layer addSublayer:selectionLayer];
        }
        
        if ([selection isEmpty])
        {
            selectionHandleLeft.hidden = YES;
            selectionHandleRight.hidden = YES;
            selectionLayer.backgroundColor = [UIColor blackColor].CGColor;
            selectionLayer.frame = [self caretRectForPosition:(ECTextPosition *)selection.start];
            [selectionLayer addAnimation:blinkAnimation forKey:@"blink"];
        }
        else
        {
            if (!selectionHandleLeft)
            {
                selectionHandleLeft = [[ECSelectionHandleView alloc] initWithFrame:CGRectNull];
                [selectionHandleLeft sizeToFit];
                selectionHandleLeft.side = ECSelectionHandleSideLeft | ECSelectionHandleSideTop;
                [self addSubview:selectionHandleLeft];
            }
            selectionHandleLeft.hidden = NO;
            
            if (!selectionHandleRight)
            {
                selectionHandleRight = [[ECSelectionHandleView alloc] initWithFrame:CGRectNull];
                [selectionHandleRight sizeToFit];
                selectionHandleRight.side = ECSelectionHandleSideRight | ECSelectionHandleSideBottom;
                [self addSubview:selectionHandleRight];
            }
            selectionHandleRight.hidden = NO;

            //
            __block CGMutablePathRef path = CGPathCreateMutable();
            __block CGRect selectionRect = CGRectNull;
            __block CGRect trackRect = CGRectNull;
            [self processRectsOfLinesInRange:[selection range] withBlock:^(CGRect rct) {
                if (CGRectIsNull(trackRect))
                    [selectionHandleLeft applyToRect:rct];
                trackRect = rct;
                selectionRect = CGRectUnion(selectionRect, rct);
                CGPathAddRect(path, NULL, rct);
            }];
            [selectionHandleRight applyToRect:trackRect];
            if (selectionPath)
                CGPathRelease(selectionPath);
            selectionPath = path;
            
            //
            selectionLayer.backgroundColor = selectionColor.CGColor;
            [selectionLayer removeAnimationForKey:@"blink"];
            selectionLayer.opacity = 0.5;
            selectionLayer.frame = selectionRect;
        }
        selectionLayer.hidden = NO;
    }
    else if (selectionLayer && !selectionLayer.hidden)
    {
        [selectionLayer removeAnimationForKey:@"blink"];
        selectionLayer.hidden = YES;
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

- (CGSize)sizeThatFits:(CGSize)size
{
    CGSize s = [super sizeThatFits:size]; //self.bounds.size;
    s.height = MAX(s.height, contentFrameRect.size.height);
    return s;
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
#pragma mark CALayer delegate

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (layer == selectionLayer)
    {
        if (selection && ![selection isEmpty] && selectionPath)
        {
            CGContextAddPath(ctx, selectionPath);
            CGContextFillPath(ctx);
            return;
        }
    }
    [super drawLayer:layer inContext:ctx];
}

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
    return [self contentLength] > 0;
}

- (void)insertText:(NSString *)aText
{
    // TODO solid carret
    
    // Select insertion range
    NSUInteger contentLength = [self contentLength];
    NSRange insertRange;
    if (!selection)
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
        [self unmarkText];
        // TODO beforeMutate
        NSRange cr = [[content string] rangeOfComposedCharacterSequenceAtIndex:s-1];
        [content deleteCharactersInRange:cr];
        // TODO afterMutate
        [self setSelectedIndex:cr.location];
        [self setNeedsContentFrame];
        [self setNeedsDisplay];
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
    if (e < s)
        return;
    
    NSUInteger contentLength = [self contentLength];
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
    
    [self setSelectedIndex:endIndex];
    
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
    NSRange replaceRange;
    NSUInteger contentLength = [self contentLength];
    
    if (markedRange.length == 0)
    {
        if (selection)
        {
            replaceRange = [selection range];
        }
        else
        {
            replaceRange.location = contentLength;
            replaceRange.length = 0;
        }
    }
    else
    {
        replaceRange = markedRange;
    }
    
    // TODO setsolidcaret and beforeMutate
    
    [content replaceCharactersInRange:replaceRange withString:markedText];
    
    // Adjust selection
    NSRange newSelectionRange;
    NSUInteger markedTextLength = [markedText length];
    if (selectedRange.location > markedTextLength 
        || selectedRange.location + selectedRange.length > markedTextLength)
    {
        newSelectionRange = (NSRange){replaceRange.location + markedTextLength, 0};
    }
    else
    {
        newSelectionRange = (NSRange){replaceRange.location + selectedRange.location, selectedRange.length};
    }
    
    
    // TODO afterMutate
    
    [self willChangeValueForKey:@"markedTextRange"];
    ECTextRange *newSelection = [[ECTextRange alloc] initWithRange:newSelectionRange];
    [self setSelectedTextRange:newSelection notifyDelegate:NO];
    [newSelection release];
    markedRange = (NSRange){replaceRange.location, markedTextLength};
    [self didChangeValueForKey:@"markedTextRange"];
    
    [self setNeedsContentFrame];
    [self setNeedsDisplay];
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
    
    NSUInteger contentLength = [self contentLength];
    if (result > contentLength)
        result = contentLength;
    
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
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:[self contentLength]] autorelease];
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
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = [self rectForContentRange:(NSRange){pos, 0}];
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
        r.length = [self contentLength];
        lineRange.location = 0;
        lineRange.length = lineCount;
    }
    
    CGPoint *origins = malloc(sizeof(CGPoint) * lineRange.length);
    CTFrameGetLineOrigins(contentFrame, lineRange, origins);
    
    // Transform point
    point = CGPointApplyAffineTransform(point, [self transormContentFrameFlipped:YES inverted:YES]);
    
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
    else if (x >= lineWidth && in_range(r, lineStringRange.location + lineStringRange.length)) 
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

- (NSUInteger)contentLength
{
    if (!content)
        return 0;
    NSUInteger len = [content length];
    if (len)
        len--;
    return len;
}

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

- (void)processRectsOfLinesInRange:(NSRange)range withBlock:(void(^)(CGRect rct))block
{
    // TODO update contentFrame if needed
    CFArrayRef lines = CTFrameGetLines(contentFrame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CFIndex firstLine = [self lineIndexForLocation:range.location 
                                           inLines:lines 
                                       containedIn:(CFRange){0, lineCount}];
    if (firstLine >= lineCount)
        firstLine = lineCount - 1;
    if (firstLine < 0)
        return;
    
    BOOL lastLine = NO;
    CGAffineTransform transform = [self transormContentFrameFlipped:YES inverted:YES];

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
        CGRect lineRect = CGRectMake(contentFrameRect.origin.x, lineOrigin.y - contentFrameRect.origin.y, 0, ascent + descent);
        
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
    CGPoint endpoint = point;
    endpoint.x += 30;
    
    [self setSelectedTextFromPoint:point toPoint:endpoint];
}

- (CGAffineTransform)transormContentFrameFlipped:(BOOL)flipped 
                                        inverted:(BOOL)inverted
{
    CGFloat scale = 1.0;
    CGRect bounds = self.bounds;
    CGAffineTransform transform = {
        scale, 0,
        0, flipped ? -scale : scale,
        bounds.origin.x + contentFrameRect.origin.x, bounds.origin.y + contentFrameRect.origin.y + contentFrameRect.size.height
    };
    return inverted ? CGAffineTransformInvert(transform) : transform;
}

@end
