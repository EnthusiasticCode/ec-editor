//
//  ECCodeView.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import <QuartzCore/QuartzCore.h>
#import "ECTextRenderer.h"
#import "ECTextPosition.h"
#import "ECTextRange.h"
#import "ECCodeStringDataSource.h"

#define TILEVIEWPOOL_SIZE (3)

#pragma mark -
#pragma mark TextTileView

@interface TextTileView : UIView {
@private
    ECTextRenderer *renderer;
}

@property (nonatomic) NSUInteger tileIndex;

@property (nonatomic) UIEdgeInsets textInsets;

- (id)initWithTextRenderer:(ECTextRenderer *)aRenderer;

- (void)invalidate;

@end


@implementation TextTileView

@synthesize tileIndex, textInsets;

- (id)initWithTextRenderer:(ECTextRenderer *)aRenderer
{
    if ((self = [super init]))
    {
        self.opaque = YES;
        self.clearsContextBeforeDrawing = NO;
        renderer = aRenderer;
    }
    return self;
}

- (void)invalidate
{
    tileIndex = NSUIntegerMax;
    self.hidden = YES;
}

- (void)drawRect:(CGRect)rect
{
    if (tileIndex == NSUIntegerMax)
        return;
    
    // TODO draw "transparent" bg and thatn draw text in deferred queue
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [self.backgroundColor setFill];
    CGContextFillRect(context, rect);
    
    // Drawing text
    CGContextSaveGState(context);
    {
        CGPoint textOffset = CGPointMake(0, rect.size.height * tileIndex);
        CGSize textSize = rect.size;
        if (tileIndex == 0) 
        {
            textSize.height -= textInsets.top;
            CGContextTranslateCTM(context, textInsets.left, textInsets.top);
        }
        else
        {
            textOffset.y -= textInsets.top;
            CGContextTranslateCTM(context, textInsets.left, 0);
        }
        CGRect textRect = (CGRect){ textOffset, rect.size };
        
        [renderer drawTextWithinRect:textRect inContext:context];
    }
    CGContextRestoreGState(context);
}

@end

#pragma mark -
#pragma mark TextSelectionView

@interface TextSelectionView : UIView {
@private
    
}

@property (nonatomic) NSRange selection;
@property (nonatomic, readonly) ECTextRange *selectionRange;
@property (nonatomic, readonly) ECTextPosition *selectionPosition;

@end


@implementation TextSelectionView

@synthesize selection;

- (ECTextRange *)selectionRange
{
    return [[[ECTextRange alloc] initWithRange:selection] autorelease];
}

- (ECTextPosition *)selectionPosition
{
    return [[[ECTextPosition alloc] initWithIndex:selection.location] autorelease];
}

@end

#pragma mark -
#pragma mark -
#pragma mark ECCodeView

@interface ECCodeView () {
@private
    NSMutableAttributedString *text;
    
    // Tileing and rendering management
    ECTextRenderer *renderer;
    TextTileView* tileViewPool[TILEVIEWPOOL_SIZE];
    
    // Text management
    TextSelectionView *selectionView;
    NSRange markedRange;
    
    // Recognizers
    UITapGestureRecognizer *focusRecognizer;
    UITapGestureRecognizer *tapRecognizer;
    
    // Flags
    ECCodeStringDataSource *defaultDatasource;
    BOOL dataSourceHasCodeCanEditTextInRange;
}

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex;

/// Method to be used before any text modification occurs.
- (void)editDataSourceInRange:(NSRange)range withString:(NSString *)string;

/// Support method to set the selection and notify the input delefate.
- (void)setSelectedTextRange:(NSRange)newSelection notifyDelegate:(BOOL)shouldNotify;

/// Convinience method to set the selection to an index location.
- (void)setSelectedIndex:(NSUInteger)index;

/// Helper method to set the selection starting from two points.
- (void)setSelectedTextFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint;

// Gestures handlers
- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer;

@end


@implementation ECCodeView

#pragma mark Properties

@synthesize datasource, textInsets;

- (void)setDatasource:(id<ECCodeViewDataSource>)aDatasource
{
    datasource = aDatasource;
    
    if (datasource != defaultDatasource) 
    {
        [defaultDatasource release];
    }
    
    dataSourceHasCodeCanEditTextInRange = [datasource respondsToSelector:@selector(codeView:canEditTextInRange:)];
    
    renderer.datasource = datasource;
}

- (void)setTextInsets:(UIEdgeInsets)insets
{
    textInsets = insets;
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setTextInsets:insets];
        [tileViewPool[i] setNeedsDisplay];
    }
}

- (void)setFrame:(CGRect)frame
{
    renderer.wrapWidth = UIEdgeInsetsInsetRect(frame, self->textInsets).size.width;
    self.contentSize = CGSizeMake(frame.size.width, renderer.estimatedHeight + textInsets.top + textInsets.bottom);
    
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, frame.size };
    }
    
    // Reposition selection
    [self setSelectedTextRange:selectionView.selection notifyDelegate:NO];
    
    [super setFrame:frame];
}

- (void)setBackgroundColor:(UIColor *)color
{
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] setBackgroundColor:color];
        [tileViewPool[i] setNeedsDisplay];
    }
    [super setBackgroundColor:color];
}

#pragma mark NSObject Methods

static void preinit(ECCodeView *self)
{
    self->renderer = [ECTextRenderer new];
    self->renderer.preferredLineCountPerSegment = 500;
    
    self->textInsets = UIEdgeInsetsMake(10, 10, 10, 10);
}

static void init(ECCodeView *self)
{    
    self->renderer.wrapWidth = UIEdgeInsetsInsetRect(self.bounds, self->textInsets).size.width;
    [self->renderer addObserver:self forKeyPath:@"estimatedHeight" options:NSKeyValueObservingOptionNew context:nil];
    
    // Adding selection view
    self->selectionView = [TextSelectionView new];
    [self->selectionView setHidden:YES];
    [self->selectionView setBackgroundColor:[UIColor redColor]];
    [self->selectionView setOpaque:YES];
    [self addSubview:self->selectionView];
    [self->selectionView release];
    
    // Adding focus recognizer
    self->focusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureFocus:)];
    [self->focusRecognizer setNumberOfTapsRequired:1];
    [self addGestureRecognizer:self->focusRecognizer];
    [self->focusRecognizer release];
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    self = [super initWithFrame:frame];
    if (self) {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder 
{
    preinit(self);
    self = [super initWithCoder:coder];
    if (self) {
        init(self);
    }
    return self;
}

- (void)dealloc
{
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
        [tileViewPool[i] release];
    [renderer release];
    [defaultDatasource release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == renderer) 
    {
        CGFloat height = [[change valueForKey:NSKeyValueChangeNewKey] floatValue];
        self.contentSize = CGSizeMake(self.bounds.size.width, height + textInsets.top + textInsets.bottom);
        return;
    }
}

- (void)didMoveToSuperview
{
    if (!self->datasource)
    {
        self->defaultDatasource = [ECCodeStringDataSource new];
        self.datasource = self->defaultDatasource;
    }
}

#pragma mark -
#pragma mark Rendering Methods

- (TextTileView *)viewForTileIndex:(NSUInteger)tileIndex
{
    NSInteger selected = -1;
    // Select free tile
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
    {
        if (tileViewPool[i])
        {
            // Tile already present and ready
            if ([tileViewPool[i] tileIndex] == tileIndex)
            {
                return tileViewPool[i];
            }
            // If still no selection just select this as a candidate
            if (selected >= 0)
                continue;
            // Select only if better than previous
            if (abs([tileViewPool[i] tileIndex] - tileIndex) <= 1) 
                continue;
        }
        selected = i;
    }
    
    // Generate new tile
    if (!tileViewPool[selected]) 
    {
        tileViewPool[selected] = [[TextTileView alloc] initWithTextRenderer:renderer];
        tileViewPool[selected].backgroundColor = self.backgroundColor;
        tileViewPool[selected].textInsets = textInsets;
        // TODO remove from self when not displayed
        [self addSubview:tileViewPool[selected]];
    }
    
    tileViewPool[selected].tileIndex = tileIndex;
    tileViewPool[selected].bounds = (CGRect){ CGPointZero, self.frame.size };
    [tileViewPool[selected] setNeedsDisplay];
    
    return tileViewPool[selected];
}

- (void)layoutSubviews
{
//    [super layoutSubviews];
    
    // Scrolled content rect
    CGRect contentRect = self.bounds;
    CGFloat halfHeight = contentRect.size.height / 2.0;
    
    // Find first visible tile index
    NSUInteger index = contentRect.origin.y / contentRect.size.height;
    
    // Layout first visible tile
    CGFloat firstTileEnd = (index + 1) * contentRect.size.height;
    TextTileView *firstTile = [self viewForTileIndex:index];
    [self sendSubviewToBack:firstTile];
    firstTile.hidden = NO;
    firstTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd - halfHeight);
    
    // Layout second visible tile if needed
    if (firstTileEnd < CGRectGetMaxY(contentRect)) 
    {
        index++;
        TextTileView *secondTile = [self viewForTileIndex:index];
        [self sendSubviewToBack:secondTile];
        secondTile.hidden = NO;
        secondTile.center = CGPointMake(CGRectGetMidX(contentRect), firstTileEnd + halfHeight);
    }
    
    // Layout selection caret
//    if ([self isFirstResponder] && selectionView.selection.length == 0)
//    {
//        CGRect caretRect = [self caretRectForPosition:selectionView.selectionPosition];
//        selectionView.frame = caretRect;
//        selectionView.hidden = NO;
//        [self bringSubviewToFront:selectionView];
//    }
}

- (void)updateAllText
{
    [renderer updateAllText];
}

- (void)updateTextInLineRange:(NSRange)originalRange toLineRange:(NSRange)newRange
{
    [renderer updateTextInLineRange:originalRange toLineRange:newRange];
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
    
    // Lazy create recognizers
    if (!tapRecognizer && shouldBecomeFirstResponder)
    {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTap:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
        
        // TODO initialize gesture recognizers
    }
    
    // Activate recognizers
    if (shouldBecomeFirstResponder)
    {
        focusRecognizer.enabled = NO;
        tapRecognizer.enabled = YES;
        //        doubleTapRecognizer.enabled = YES;
        //        tapHoldRecognizer.enabled = YES;
    }
    
    [self setNeedsLayout];
    
    return shouldBecomeFirstResponder;   
}

- (BOOL)resignFirstResponder
{
    BOOL shouldResignFirstResponder = [super resignFirstResponder];
    
    if (![self isFirstResponder])
    {
        focusRecognizer.enabled = YES;
        tapRecognizer.enabled = NO;
        //        doubleTapRecognizer.enabled = NO;
        //        tapHoldRecognizer.enabled = NO;
        
        // TODO remove thumbs
    }
    
    [self setNeedsLayout];
    
    // TODO call delegate's endediting
    
    return shouldResignFirstResponder;
}

#pragma mark -
#pragma mark UIKeyInput protocol

- (BOOL)hasText
{
    return [datasource textLength] > 0;
}

- (void)insertText:(NSString *)string
{
    // Select insertion range
//    NSUInteger textLength = [datasource textLength];
    NSRange insertRange = selectionView.selection;
//    if (!selection)
//    {
//        insertRange = (NSRange){ textLength, 0 };
//    }
//    else
//    {
//        NSUInteger s = ((ECTextPosition*)selection.start).index;
//        NSUInteger e = ((ECTextPosition*)selection.end).index;
//        if (s > textLength)
//            s = textLength;
//        if (e > textLength)
//            e = textLength;
//        if (e < s)
//            return;
//        insertRange = (NSRange){ s, e - s };
//    }
    
    // TODO check if char is space and autocomplete
    
    [self editDataSourceInRange:insertRange withString:string];
    [self setSelectedIndex:(insertRange.location + [string length])];
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
        NSRange cr = (NSRange){ s - 1, 1 };
        [self editDataSourceInRange:cr withString:nil];
        [self setSelectedIndex:cr.location];
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

// TODO create a proper code tokenizer, should be retreived from the datasource
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
        result = [datasource codeView:self stringInRange:(NSRange){s, e - s}];
    
    return result;
}

- (void)replaceRange:(UITextRange *)range withText:(NSString *)string
{
    // Adjust replacing range
    if(!range || ![range isKindOfClass:[ECTextRange class]])
        return;
    
    NSUInteger s = ((ECTextPosition *)range.start).index;
    NSUInteger e = ((ECTextPosition *)range.end).index;
    if (e < s)
        return;
    
    NSUInteger textLength = [datasource textLength];
    if (s > textLength)
        s = textLength;
    
    NSUInteger endIndex;
    if (e > s)
    {
        NSRange c = (NSRange){s, e - s};
        if (c.location + c.length > textLength)
            c.length = textLength - c.location;
        [self editDataSourceInRange:c withString:string];
        endIndex = c.location + [string length];
    }
    else
    {
        [self editDataSourceInRange:(NSRange){s, 0} withString:string];
        endIndex = s + [string length];
    }
    [self setSelectedIndex:endIndex];
}

#pragma mark Working with Marked and Selected Text

- (UITextRange *)selectedTextRange
{
    return selectionView.selectionRange;
}

- (void)setSelectedTextRange:(UITextRange *)selectedTextRange
{
    // TODO solidCaret
    
    [self unmarkText];
    
    [self setSelectedTextRange:[(ECTextRange *)selectedTextRange range] notifyDelegate:YES];
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
//    NSUInteger textLength = [self textLength];
    
    if (markedRange.length == 0)
    {
        replaceRange = selectionView.selection;
//        if (selection)
//        {
//            replaceRange = [selection range];
//        }
//        else
//        {
//            replaceRange.location = textLength;
//            replaceRange.length = 0;
//        }
    }
    else
    {
        replaceRange = markedRange;
    }
    
    NSRange newSelectionRange;
    NSUInteger markedTextLength = [markedText length];
    [self editDataSourceInRange:replaceRange withString:markedText];
    
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
    [self setSelectedTextRange:newSelectionRange notifyDelegate:NO];
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
    
    if (direction == UITextStorageDirectionForward || direction == UITextStorageDirectionBackward) 
    {
        if (direction == UITextStorageDirectionBackward)
            offset = -offset;
        
        if (offset < 0 && (NSUInteger)(-offset) >= pos)
            result = 0;
        else
            result = pos + offset;
    } 
    else if (direction == UITextLayoutDirectionLeft || direction == UITextLayoutDirectionRight) 
    {
        if (direction == UITextLayoutDirectionLeft)
            offset = -offset;
        
        // TODO should move considering typography characters
        if (offset < 0 && (NSUInteger)(-offset) >= pos)
            result = 0;
        else
            result = pos + offset;
    } 
    else if (direction == UITextLayoutDirectionUp || direction == UITextLayoutDirectionDown) 
    {
        if (direction == UITextLayoutDirectionUp)
            offset = -offset;

        // TODO!!! chech if make sense
//        CGFloat frameOffset;
//        CTFrameRef frame = [self frameContainingTextIndex:pos frameOffset:&frameOffset];
//        
//        CFArrayRef lines = CTFrameGetLines(frame);
//        CFIndex lineCount = CFArrayGetCount(lines);
//        CFIndex lineIndex = ECCTFrameGetLineContainingStringIndex(frame, pos, (CFRange){0, lineCount}, NULL);
//        CFIndex newIndex = lineIndex + offset;
//        CTLineRef line = CFArrayGetValueAtIndex(lines, lineIndex);
//        
//        if (newIndex < 0 || newIndex >= lineCount)
//            return nil;
//        
//        if (newIndex == lineIndex)
//            return position;
//        
//        CGFloat xPosn = CTLineGetOffsetForStringIndex(line, pos, NULL) + frameOffset;
//        CGPoint origins[1];
//        CTFrameGetLineOrigins(frame, (CFRange){lineIndex, 1}, origins);
//        xPosn = xPosn + origins[0].x; // X-coordinate in layout space
//        
//        CTFrameGetLineOrigins(frame, (CFRange){newIndex, 1}, origins);
//        xPosn = xPosn - origins[0].x; // X-coordinate in new line's local coordinates
//        
//        CFIndex newStringIndex = CTLineGetStringIndexForPosition(CFArrayGetValueAtIndex(lines, newIndex), (CGPoint){xPosn, 0});
//        
//        if (newStringIndex == kCFNotFound)
//            return nil;
//        
//        if(newStringIndex < 0)
//            newStringIndex = 0;
//        result = newStringIndex;
    } 
    else 
    {
        // Direction unimplemented
        return position;
    }
    
    NSUInteger textLength = [datasource textLength];
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
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:[datasource textLength]] autorelease];
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
    
    CGRect r = [renderer boundsForStringRange:[(ECTextRange *)range range] limitToFirstLine:YES];
    return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    //    NSUInteger pos = ((ECTextPosition *)position).index;
    //    CGFloat frameOffset;
    ////    CTFrameRef frame = [self frameContainingTextIndex:pos frameOffset:&frameOffset];
    ////    CGRect carretRect = ECCTFrameGetBoundRectOfLinesForStringRange(frame, (CFRange){pos, 0});
    //    CGRect carretRect = CGRectZero;
    //    carretRect.origin.x += frameOffset;
    //    // TODO parametrize caret rect sizes
    //    carretRect.origin.x -= 1.0;
    //    carretRect.size.width = 2.0;
    //    return carretRect;
    
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = [renderer boundsForStringRange:(NSRange){pos, 0} limitToFirstLine:YES];
    
    carretRect.origin.x += textInsets.left;
    carretRect.origin.y += textInsets.top;
    
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
    
    point.x -= textInsets.left;
    point.y -= textInsets.top;
    NSUInteger location = [renderer closestStringLocationToPoint:point withinStringRange:[(ECTextRange *)range range]];
    return [[[ECTextPosition alloc] initWithIndex:location] autorelease];;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    ECTextPosition *pos = (ECTextPosition *)[self closestPositionToPoint:point];
    
    NSRange r = [[datasource codeView:self stringInRange:(NSRange){ pos.index, 1 }] rangeOfComposedCharacterSequenceAtIndex:0];
    
    if (r.location == NSNotFound)
        return nil;
    
    return [[[ECTextRange alloc] initWithRange:r] autorelease];
}

#pragma mark -
#pragma mark Private methods

- (void)editDataSourceInRange:(NSRange)range withString:(NSString *)string
{
    if (dataSourceHasCodeCanEditTextInRange
        && [datasource codeView:self canEditTextInRange:range]) 
    {
        [self unmarkText];
        
        [inputDelegate textWillChange:self];
        
        [datasource codeView:self commitString:string forTextInRange:range];
        
        [inputDelegate textDidChange:self];
    }
}

- (void)setSelectedTextRange:(NSRange)newSelection notifyDelegate:(BOOL)shouldNotify
{
    if (shouldNotify && NSEqualRanges(selectionView.selection, newSelection))
        return;

    //    if (newSelection && (![newSelection isEmpty])) // TODO or solid caret
    //        [self setNeedsDisplayInRange:newSelection];
    
    if (shouldNotify)
        [inputDelegate selectionWillChange:self];
    
    selectionView.selection = newSelection;
    
    if (shouldNotify)
        [inputDelegate selectionDidChange:self];
    
    // Position selection view
    // TODO multiselection
    if ([self isFirstResponder] && selectionView.selection.length == 0)
    {
        CGRect caretRect = [self caretRectForPosition:selectionView.selectionPosition];
        selectionView.frame = caretRect;
        selectionView.hidden = NO;
        [self bringSubviewToFront:selectionView];
    }
}

- (void)setSelectedIndex:(NSUInteger)index
{
    [self setSelectedTextRange:(NSRange){index, 0} notifyDelegate:NO];
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
#pragma mark Text Renderer Delegate

- (void)textRenderer:(ECTextRenderer *)sender invalidateRenderInRect:(CGRect)rect
{
    if (rect.origin.y <= CGRectGetMaxY(self.bounds)) 
    {
        for (int i = 0; i < TILEVIEWPOOL_SIZE; ++i) 
        {
            [tileViewPool[i] setNeedsDisplay];
        }
    }
}

#pragma mark -
#pragma mark Gesture Recognizers and Interaction

- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer
{
    [self becomeFirstResponder];
    [self handleGestureTap:recognizer];
}

- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self];
    [self setSelectedTextFromPoint:tapPoint toPoint:tapPoint];
}

#pragma mark -
#pragma mark Text Renderer and CodeView String Datasource

- (NSString *)text
{
    if (![datasource isKindOfClass:[ECCodeStringDataSource class]])
    {
        return nil;
    }
    
    return [(ECCodeStringDataSource *)datasource string];
}

- (void)setText:(NSString *)string
{
    // Will make sure that if no datasource have been set, a default one will be created.
    [self didMoveToSuperview];
    
    if (![datasource isKindOfClass:[ECCodeStringDataSource class]])
    {
        [NSException raise:NSInternalInconsistencyException format:@"Trying to set codeview text with textDelegate not self."];
        return;
    }
    
    // Set text
    [(ECCodeStringDataSource *)datasource setString:string];
    [renderer updateAllText];

    // Update tiles
    CGRect bounds = self.bounds;
    renderer.wrapWidth = UIEdgeInsetsInsetRect(bounds, self->textInsets).size.width;
    self.contentSize = CGSizeMake(bounds.size.width, renderer.estimatedHeight + textInsets.top + textInsets.bottom);
    for (NSInteger i = 0; i < TILEVIEWPOOL_SIZE; ++i)
    {
        [tileViewPool[i] invalidate];
        tileViewPool[i].bounds = (CGRect){ CGPointZero, bounds.size };
    }
    
    // Update selection
    // TODO resume saved selection
    [self setSelectedTextRange:(NSRange){ 0, 0 } notifyDelegate:NO];
    
    [self setNeedsLayout];
}


@end
