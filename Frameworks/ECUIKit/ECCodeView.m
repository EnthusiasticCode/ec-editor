//
//  ECCodeView.m
//  CodeView3
//
//  Created by Nicola Peduzzi on 12/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCodeView.h"
#import <QuartzCore/QuartzCore.h>
#import "ECTextPosition.h"
#import "ECTextRange.h"

#pragma mark -
#pragma mark Interfaces

@class CodeInfoView;
@class TextSelectionView;

#pragma mark -

@interface ECCodeView () {
@private
    // Navigator
    CodeInfoView *infoView;
    
    // Text management
    TextSelectionView *selectionView;
    NSRange markedRange;
    
    // Recognizers
    UITapGestureRecognizer *focusRecognizer;
    UITapGestureRecognizer *tapRecognizer;
}

/// Specify if the info view containing search marks and navigator should be visible.
@property (nonatomic, getter = isInfoViewVisible) BOOL infoViewVisible;

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

#pragma mark -
@interface TextSelectionView : UIView

@property (nonatomic) NSRange selection;
@property (nonatomic, readonly) ECTextRange *selectionRange;
@property (nonatomic, readonly) ECTextPosition *selectionPosition;

@end

#pragma mark -

@interface CodeInfoView : UIView {
@private
    id<ECCodeViewDataSource> datasource;
    ECTextRenderer *renderer;
    NSOperationQueue *renderingQueue;
    
    ECCodeViewBase *navigatorView;
    
    UITapGestureRecognizer *tapRecognizer;
}

- (id)initWithNavigatorDatasource:(id<ECCodeViewDataSource>)source 
                         renderer:(ECTextRenderer *)aRenderer 
                   renderingQueue:(NSOperationQueue *)queue;

#pragma mark Parent Layout

@property (nonatomic) CGSize parentSize;

@property (nonatomic) CGFloat parentContentOffsetRatio;

#pragma mark Info View Layout and Style

@property (nonatomic) CGFloat normalWidth;

@property (nonatomic) CGFloat navigatorWidth;

@property (nonatomic, readonly) CGFloat currentWidth;

@property (nonatomic) UIEdgeInsets navigatorInsets;

@property (nonatomic, retain) UIColor *navigatorBackgroundColor;

@property (nonatomic, getter = isNavigatorVisible) BOOL navigatorVisible;

@property (nonatomic) CGFloat navigatorHideDelay;

- (void)setNavigatorVisible:(BOOL)visible animated:(BOOL)animated;

#pragma mark User Interaction

- (void)updateNavigator;

- (void)handleTap:(UITapGestureRecognizer *)recognizer;

@end

#pragma mark -
#pragma mark Implementations

#pragma mark -
#pragma mark TextSelectionView

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
#pragma mark CodeInfoView

@implementation CodeInfoView

@synthesize parentSize, parentContentOffsetRatio;
@synthesize normalWidth, navigatorWidth;
@synthesize navigatorInsets, navigatorVisible, navigatorBackgroundColor, navigatorHideDelay;

- (id)initWithNavigatorDatasource:(id<ECCodeViewDataSource>)source renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue
{
    parentSize = [UIScreen mainScreen].bounds.size;
    normalWidth = 11;
    navigatorHideDelay = 1;
    navigatorInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    if ((self = [super init])) 
    {
        datasource = source;
        renderer = aRenderer;
        renderingQueue = queue;
        
        self.backgroundColor = [UIColor clearColor];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapRecognizer];
        [tapRecognizer release];
    }
    return self;
}

- (void)dealloc
{
    [navigatorBackgroundColor release];
    [navigatorView release];
    [super dealloc];
}

- (void)setParentSize:(CGSize)size
{
    if (CGSizeEqualToSize(size, parentSize))
        return;
    
    parentSize = size;
    
    if (!navigatorVisible)
        return;
    
    navigatorView.contentScaleFactor = (navigatorWidth - navigatorInsets.left - navigatorInsets.right) / parentSize.width;
}

- (void)setParentContentOffsetRatio:(CGFloat)ratio
{
    if (ratio == parentContentOffsetRatio)
        return;
    
    parentContentOffsetRatio = ratio;
    
    if (!navigatorVisible)
        return;
    
    CGFloat height = (navigatorView.contentSize.height - navigatorView.bounds.size.height);
    navigatorView.contentOffset = CGPointMake(0, height > 0 ? parentContentOffsetRatio * height : 0);
}

- (CGFloat)currentWidth
{
    return navigatorVisible ? normalWidth + navigatorWidth : normalWidth;
}

- (void)setNavigatorVisible:(BOOL)visible
{
    [self setNavigatorVisible:visible animated:NO];
}

- (void)setNavigatorVisible:(BOOL)visible animated:(BOOL)animated
{
    if (visible == navigatorVisible)
        return;
    
    navigatorVisible = visible;
    
    if (!navigatorView) 
    {
        CGRect frame = self.bounds;
        frame.size.width = navigatorWidth;
        frame = UIEdgeInsetsInsetRect(frame, navigatorInsets);
        navigatorView = [[ECCodeViewBase alloc] initWithFrame:frame renderer:renderer renderingQueue:renderingQueue];
        navigatorView.datasource = datasource;
        navigatorView.contentScaleFactor = (navigatorWidth - navigatorInsets.left - navigatorInsets.right) / parentSize.width;
        navigatorView.backgroundColor = [UIColor whiteColor];
        navigatorView.scrollEnabled = NO;
        [self updateNavigator];
        CGFloat height = (navigatorView.contentSize.height - navigatorView.bounds.size.height);
        navigatorView.contentOffset = CGPointMake(0, height > 0 ? parentContentOffsetRatio * height : 0);
    }
    
    navigatorView.alpha = visible ? 0 : 1;
    
    if (visible) 
    {
        [self addSubview:navigatorView];
    }
    
    [UIView animateWithDuration:0.25 delay:(visible ? 0 : navigatorHideDelay) options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut) animations:^(void) {
        CGRect newFrame = self.frame;
        if (visible) 
        {
            self.backgroundColor = navigatorBackgroundColor;
            newFrame.origin.x -= navigatorWidth;
            newFrame.size.width += navigatorWidth;
        }
        else
        {
            navigatorView.alpha = 0;
            self.backgroundColor = [UIColor clearColor];
            newFrame.origin.x += navigatorWidth;
            newFrame.size.width -= navigatorWidth;
        }
        self.frame = newFrame;
    } completion:^(BOOL finished) {
        if (visible) 
        {
            [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
                navigatorView.alpha = 1;
            } completion:nil];
        }
        else
        {
            [navigatorView removeFromSuperview];
        }
    }];
}

- (void)updateNavigator
{    
    if (!navigatorVisible)
        return;
    
    CGRect frame = self.bounds;
    frame.size.width = navigatorWidth;
    frame = UIEdgeInsetsInsetRect(frame, navigatorInsets);
    
    // Resetting the frame will trigger actual layout update
    navigatorView.frame = frame;
    [navigatorView setNeedsLayout];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    [self setNavigatorVisible:!navigatorVisible animated:YES];
}

@end

#pragma mark -
#pragma mark ECCodeView

@implementation ECCodeView

#pragma mark -
#pragma mark Properties

@synthesize infoViewVisible;
@synthesize navigatorAutoVisible;
@synthesize navigatorBackgroundColor;
@synthesize navigatorWidth;

- (void)setFrame:(CGRect)frame
{
    if (self.navigatorVisible) 
        infoView.parentSize = frame.size;

    [super setFrame:frame];    
}

- (void)setContentSize:(CGSize)contentSize
{
    [super setContentSize:contentSize];
    
    [infoView updateNavigator];
}

#pragma mark NSObject Methods

static void preinit(ECCodeView *self)
{
    self->navigatorBackgroundColor = self.backgroundColor;
    self->navigatorWidth = 200;
}

static void init(ECCodeView *self)
{
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
    
    
    self.infoViewVisible = YES;
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
    [navigatorBackgroundColor release];
    [infoView release];
    [super dealloc];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (infoViewVisible) 
    {
        CGRect infoFrame = self.bounds;
        infoView.parentContentOffsetRatio = infoFrame.origin.y / (self.contentSize.height - infoFrame.size.height);
        
        CGFloat infoWidth = infoView.currentWidth;
        infoFrame.origin.x = infoFrame.size.width - infoWidth;
        infoFrame.size.width = infoWidth;
        infoView.frame = infoFrame;
    }
}

#pragma mark -
#pragma mark InfoView and Navigator methods

- (void)setInfoViewVisible:(BOOL)visible
{
    if (visible == infoViewVisible)
        return;
    
    infoViewVisible = visible;
    
    if (visible) 
    {
        if (!infoView)
        {
            infoView = [[CodeInfoView alloc] initWithNavigatorDatasource:datasource renderer:renderer renderingQueue:renderingQueue];
            infoView.navigatorBackgroundColor = navigatorBackgroundColor;
            infoView.navigatorWidth = navigatorWidth;
            infoView.parentSize = self.bounds.size;
        }
        [self addSubview:infoView];
    }
    else
    {
        [infoView removeFromSuperview];
    }
}

- (BOOL)isNavigatorVisible
{
    return infoView.navigatorVisible;
}

- (void)setNavigatorVisible:(BOOL)visible
{
    if (visible == infoView.navigatorVisible)
        return;
    
    if (visible)
    {
        self.infoViewVisible = YES;
        [infoView setNavigatorVisible:YES animated:YES];
    }
    else
    {
        [infoView setNavigatorVisible:NO animated:YES];
    }
}

- (void)setNavigatorWidth:(CGFloat)width
{
    navigatorWidth = width;
    infoView.navigatorWidth = width;
}

- (void)setNavigatorBackgroundColor:(UIColor *)color
{
    [navigatorBackgroundColor release];
    navigatorBackgroundColor = [color retain];
    infoView.navigatorBackgroundColor = color;
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
    NSRange insertRange = selectionView.selection;
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
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = [renderer boundsForStringRange:(NSRange){pos, 0} limitToFirstLine:YES];
    
    carretRect.origin.x += textInsets.left;
    carretRect.origin.y += textInsets.top;
    
    carretRect.origin.x -= 1.0;
    carretRect.size.width = 2.0;
    
    CGFloat scale = self.contentScaleFactor;
    if (scale != 1.0) 
    {
        carretRect.origin.x *= scale;
        carretRect.origin.y *= scale;
        carretRect.size.width *= scale;
        carretRect.size.height *= scale;
    }
    
    return carretRect;
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point
{
    return [self closestPositionToPoint:point withinRange:nil];
}

- (UITextPosition *)closestPositionToPoint:(CGPoint)point 
                               withinRange:(UITextRange *)range
{
    point.x -= textInsets.left;
    point.y -= textInsets.top;
    
    CGFloat scale = self.contentScaleFactor;
    if (scale != 1.0)
    {
        point.x /= scale;
        point.y /= scale;
    }
    
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

@end
