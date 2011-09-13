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
#import "NSTimer+block.h"
#import "ECPopoverController.h"

#import "ECCodeViewTokenizer.h"

#define CARET_WIDTH 2

#pragma mark -
#pragma mark Interfaces

@class TextSelectionView;
@class TextMagnificationView;
@class CodeInfoView;

#pragma mark -

@interface ECCodeView () {
@private    
    // Navigator
    CodeInfoView *infoView;
    
    // Text management
    TextSelectionView *selectionView;
    ECPopoverController *completionPopover;
    NSRange markedRange;
    
    // Touch scrolling timer
    NSTimer *touchScrollTimer;
    
    // Delegate and datasource flags
    BOOL dataSourceHasCodeCanEditTextInRange;
    BOOL dataSourceHasViewControllerForCompletionAtTextInRange;
    BOOL delegateHasCompletionRequestAtTextLocationWithFilterWord;
    
    // Recognizers
    UITapGestureRecognizer *focusRecognizer;
    UITapGestureRecognizer *tapRecognizer;
    UITapGestureRecognizer *tapTwoTouchesRecognizer;
    UITapGestureRecognizer *doubleTapRecognizer;
    UILongPressGestureRecognizer *longPressRecognizer;
    UILongPressGestureRecognizer *longDoublePressRecognizer;
    id<UITextInputTokenizer> _tokenizer;
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

/// Given a touch point on the top or bottom of the codeview, this method
/// scroll the content faster as the point approaches the receiver's bounds.
- (void)autoScrollForTouchAtPoint:(CGPoint)point;

- (void)showCompletionForTextInRange:(NSRange)textRange;

// Gestures handlers
- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureTapTwoTouches:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureDoubleTap:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureLongPress:(UILongPressGestureRecognizer *)recognizer;

@end

#pragma mark -

@interface TextMagnificationView : UIView {
@private
    ECCodeView *parent;
    UIImage *detailImage;
}

- (id)initWithFrame:(CGRect)frame codeView:(ECCodeView *)codeView;

- (void)detailTextAtPoint:(CGPoint)point 
            magnification:(CGFloat)magnification 
   additionalDrawingBlock:(void(^)(CGContextRef context, CGPoint textOffset))block;

@end

#pragma mark -

@interface TextSelectionKnobView : UIView

@property (nonatomic) UITextLayoutDirection knobDirection;
@property (nonatomic) CGFloat knobDiameter;

@property (nonatomic) CGRect caretRect;
@property (nonatomic, strong) UIColor *caretColor;

@end

#pragma mark -

@interface TextSelectionView : UIView {
@private
    ECCodeView *parent;
    ECRectSet *selectionRects;
    
    CABasicAnimation *blinkAnimation;
    NSTimer *blinkDelayTimer;
    
    TextSelectionKnobView *leftKnob, *rightKnob;
    UILongPressGestureRecognizer *leftKnobRecognizer, *rightKnobRecognizer;
}

- (id)initWithFrame:(CGRect)frame codeView:(ECCodeView *)codeView;

#pragma mark Managin the Selection

@property (nonatomic) NSRange selection;
@property (nonatomic, weak) ECTextRange *selectionRange;
@property (nonatomic, readonly) ECTextPosition *selectionPosition;
@property (nonatomic, readonly, getter = isEmpty) BOOL empty;
@property (nonatomic, readonly) BOOL hasSelection;

#pragma mark Selection Styles

@property (nonatomic, strong) UIColor *selectionColor;
@property (nonatomic, strong) UIColor *caretColor;
@property (nonatomic, getter = isBlinking) BOOL blink;

#pragma mark Magnification

@property (nonatomic, getter = isMagnifying) BOOL magnify;
@property (nonatomic, readonly, strong) ECPopoverController *magnificationPopover;
@property (nonatomic, readonly, strong) TextMagnificationView *magnificationView;

- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect ratio:(BOOL)ratio animated:(BOOL)animated;

- (void)handleKnobGesture:(UILongPressGestureRecognizer *)recognizer;

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

- (id)initWithFrame:(CGRect)frame 
navigatorDatasource:(id<ECCodeViewDataSource>)source 
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

@property (nonatomic, strong) UIColor *navigatorBackgroundColor;

@property (nonatomic, getter = isNavigatorVisible) BOOL navigatorVisible;

- (void)setNavigatorVisible:(BOOL)visible animated:(BOOL)animated;

#pragma mark User Interaction

- (void)updateNavigator;

- (void)handleTap:(UITapGestureRecognizer *)recognizer;

@end

#pragma mark -
#pragma mark Implementations

#pragma mark -
#pragma mark TextMagnificationView

@implementation TextMagnificationView

- (id)initWithFrame:(CGRect)frame codeView:(ECCodeView *)codeView
{
    if ((self = [super initWithFrame:frame])) 
    {
        parent = codeView;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    [self.backgroundColor setFill];
    UIRectFill(rect);
    
    @synchronized(detailImage)
    {
        [detailImage drawInRect:rect];
    }
}

- (void)detailTextAtPoint:(CGPoint)point magnification:(CGFloat)magnification additionalDrawingBlock:(void(^)(CGContextRef, CGPoint))block
{
    // Generate required text rect
    CGRect textRect = (CGRect){ point, self.bounds.size };
    textRect.size.width /= magnification;
    textRect.size.height /= magnification;
    textRect.origin.x -= (textRect.size.width / 2);
    textRect.origin.y -= (textRect.size.height / 2);
    
    // Check to be contained in text bounds
    if (textRect.origin.x < -10)
        textRect.origin.x = -10;
    else if (CGRectGetMaxX(textRect) > parent.renderer.wrapWidth + 10)
        textRect.origin.x = parent.renderer.wrapWidth - textRect.size.width + 10;
    // Render magnified image
    __weak TextMagnificationView *this = self;
    [parent.renderingQueue addOperationWithBlock:^(void) {
        UIGraphicsBeginImageContext(this.bounds.size);
        // Prepare magnified context
        CGContextRef imageContext = UIGraphicsGetCurrentContext();        
        CGContextScaleCTM(imageContext, magnification, magnification);
        CGContextTranslateCTM(imageContext, -textRect.origin.x, 0);
        // Render text
        CGContextSaveGState(imageContext);
        [this->parent.renderer drawTextWithinRect:textRect inContext:imageContext];
        CGContextRestoreGState(imageContext);
        // Render additional drawings
        if (block)
            block(imageContext, textRect.origin);
        // Get result image
        @synchronized(this->detailImage)
        {
            this->detailImage = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        // Request rerendering
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            [this setNeedsDisplay];
        }];
    }];
}

@end

#pragma mark -
#pragma mark TextSelectionKnobView

#define KNOB_SIZE 30.0

@implementation TextSelectionKnobView

@synthesize knobDirection, knobDiameter;
@synthesize caretRect, caretColor;

- (void)setCaretRect:(CGRect)rect
{
    caretRect = rect;
    
    // Set frame considering knob direction
    // The given rect has origin where the selection start/end
    rect.size.width = KNOB_SIZE;
    rect.origin.x -= KNOB_SIZE / 2;
    rect.size.height = KNOB_SIZE;
    rect.origin.y -= (KNOB_SIZE - caretRect.size.height) / 2;
    self.frame = rect;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) 
    {
        knobDiameter = 10;
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [caretColor setFill];
    
    // Draw caret
    CGRect bounds = self.bounds;
    CGRect caret = caretRect;
    caret.origin.x = CGRectGetMidX(bounds) - CARET_WIDTH / 2;
    caret.origin.y = CGRectGetMidY(bounds) - caretRect.size.height / 2;
    CGContextFillRect(context, caret);
    
    // Draw knob
    CGContextAddArc(context, CGRectGetMidX(caret), knobDirection == UITextLayoutDirectionRight ? CGRectGetMaxY(caret) : caret.origin.y, knobDiameter / 2, -M_PI, M_PI, 0);
    CGContextFillPath(context);
}

@end

#pragma mark -
#pragma mark TextSelectionView

@implementation TextSelectionView

#pragma mark Properties

@synthesize selection, hasSelection;
@synthesize selectionColor, caretColor, blink;

- (void)setSelection:(NSRange)range
{
    if (NSEqualRanges(range, selection))
        return;
    
    hasSelection = YES;
    selection = range;
    if (blinkDelayTimer)
    {
        [blinkDelayTimer invalidate];
        blinkDelayTimer = nil;
    }
    self.blink = NO;
    
    // Set new selection frame
    CGRect frame;
    if (selection.length == 0) 
    {
        frame = [parent caretRectForPosition:self.selectionPosition];
        self.frame = frame;
        [leftKnob removeFromSuperview];
        leftKnobRecognizer.enabled = NO;
        [rightKnob removeFromSuperview];
        rightKnobRecognizer.enabled = NO;
        
        // Start blinking after the selection change has stopped
        blinkDelayTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 usingBlock:^(NSTimer *timer) {
            self.blink = YES;
            blinkDelayTimer = nil;
        } repeats:NO];
    }
    else
    {        
        selectionRects = [parent.renderer rectsForStringRange:selection limitToFirstLine:NO];
        frame = selectionRects.bounds;
        self.frame = frame;
        
        // Left knob
        if (!leftKnob) 
        {
            leftKnob = [TextSelectionKnobView new];
            leftKnob.caretColor = caretColor;
            leftKnob.knobDirection = UITextLayoutDirectionLeft;
        }
        // TODO!!! set knob 'caret'
        CGRect knobRect = [selectionRects topLeftRect];
        knobRect.size.width = CARET_WIDTH;
        leftKnob.caretRect = knobRect;
        [parent addSubview:leftKnob];
        if (!leftKnobRecognizer) 
        {
            leftKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
            leftKnobRecognizer.minimumPressDuration = 0;
            [leftKnob addGestureRecognizer:leftKnobRecognizer];
        }
        leftKnobRecognizer.enabled = YES;
        
        // Right knob
        if (!rightKnob) 
        {
            rightKnob = [TextSelectionKnobView new];
            rightKnob.caretColor = caretColor;
            rightKnob.knobDirection = UITextLayoutDirectionRight;
        }
        knobRect = [selectionRects bottomRightRect];
        knobRect.origin.x = CGRectGetMaxX(knobRect);
        knobRect.size.width = CARET_WIDTH;
        rightKnob.caretRect = knobRect;
        [parent addSubview:rightKnob];
        if (!rightKnobRecognizer) 
        {
            rightKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
            rightKnobRecognizer.minimumPressDuration = 0;
            [rightKnob addGestureRecognizer:rightKnobRecognizer];
        }
        rightKnobRecognizer.enabled = YES;
    }
    
    [self setNeedsDisplay];
}

- (ECTextRange *)selectionRange
{
    return [[ECTextRange alloc] initWithRange:selection];
}

- (void)setSelectionRange:(ECTextRange *)selectionRange
{
    self.selection = [selectionRange range];
}

- (ECTextPosition *)selectionPosition
{
    return [[ECTextPosition alloc] initWithIndex:selection.location];
}

- (BOOL)isEmpty
{
    return selection.length == 0;
}

#pragma mark Blinking

- (void)setBlink:(BOOL)doBlink
{
    if (blink == doBlink)
        return;
    
    blink = doBlink;
    
    if (!blinkAnimation) 
    {
        blinkAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        blinkAnimation.fromValue = [NSNumber numberWithFloat:1.0];
        blinkAnimation.toValue = [NSNumber numberWithFloat:0.0];
        blinkAnimation.repeatCount = CGFLOAT_MAX;
        blinkAnimation.autoreverses = YES;
        blinkAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        blinkAnimation.duration = 0.6;
    }
    
    if (blink) 
    {
        [self.layer addAnimation:blinkAnimation forKey:@"blink"];
    }
    else
    {
        [self.layer removeAnimationForKey:@"blink"];
        self.layer.opacity = 1.0;
    }
}

#pragma mark Magnification

@synthesize magnify, magnificationPopover;

- (void)setMagnify:(BOOL)doMagnify
{
    if (magnify == doMagnify)
        return;
    
    [self setMagnify:doMagnify fromRect:self.frame ratio:2 animated:YES];
}

- (void)setMagnify:(BOOL)doMagnify fromRect:(CGRect)rect ratio:(BOOL)ratio animated:(BOOL)animated
{
    magnify = doMagnify;
    
    if (!magnify) 
    {
        self.blink = selection.length == 0;
        [self.magnificationPopover dismissPopoverAnimated:animated];
    }
    else
    {
        // Stop blinking
        if (blinkDelayTimer)
        {
            [blinkDelayTimer invalidate];
            blinkDelayTimer = nil;
        }
        self.blink = NO;
        
        // Magnify at the center of given rect
        CGPoint textPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        [self.magnificationView detailTextAtPoint:textPoint magnification:ratio additionalDrawingBlock:^(CGContextRef context, CGPoint textOffset) {
            if (selection.length == 0) 
            {
                // Draw caret
                CGRect detailCaretRect = self.frame;
                detailCaretRect.origin.y -= textOffset.y;
                [caretColor setFill];
                UIRectFill(detailCaretRect);    
            }
            else
            {
                // Draw selection
                [selectionColor setFill];
                CGContextTranslateCTM(context, 0, -textOffset.y);
                [selectionRects addRectsToContext:context];
                CGContextFillPath(context);
            }
        }];
        
        // Show popover
        rect.origin.y -= parent.contentOffset.y;
        [self.magnificationPopover presentPopoverFromRect:rect inView:parent permittedArrowDirections:UIPopoverArrowDirectionDown animated:animated];
    }
}

- (ECPopoverController *)magnificationPopover
{
    if (!magnificationPopover) 
    {
        magnificationPopover = [[ECPopoverController alloc] initWithContentViewController:nil];
        magnificationPopover.automaticDismiss = NO;
        // TODO size with proportional text line height
        [magnificationPopover setPopoverContentSize:(CGSize){200, 40} animated:NO];
        
        TextMagnificationView *detail = [[TextMagnificationView alloc] initWithFrame:CGRectMake(0, 0, 200, 40) codeView:parent];
        detail.backgroundColor = parent.backgroundColor;
        // TODO make this more efficient
        detail.layer.cornerRadius = 3;
        detail.layer.masksToBounds = YES;
        
        magnificationPopover.popoverView.contentView = detail;
        
    }
    return magnificationPopover;
}

- (TextMagnificationView *)magnificationView
{
    return (TextMagnificationView *)self.magnificationPopover.popoverView.contentView;
}

- (void)handleKnobGesture:(UILongPressGestureRecognizer *)recognizer
{
    // TODO it may be needed to change thumbs hit test, see ouieditableframe 1842
    
    CGPoint tapPoint = [recognizer locationInView:parent];
    CGPoint textPoint = tapPoint;
    
    // Retrieving position
    NSUInteger pos = [parent.renderer closestStringLocationToPoint:textPoint withinStringRange:(NSRange){0, 0}];
    
    // Changing selection
    if (recognizer.view == rightKnob) 
    {   
        if (pos > selection.location) 
        {
            self.selection = NSMakeRange(selection.location, pos - selection.location);
        }
    }
    else // leftKnob
    {
        if (pos < NSMaxRange(selection)) 
        {
            self.selection = NSMakeRange(pos, NSMaxRange(selection) - pos);
        }
    }
    
    // Magnification
    BOOL animatePopover = NO;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            self.magnify = NO;
            break;
            
        case UIGestureRecognizerStateBegan:
            animatePopover = YES;
            
        default:
        {
            CGRect knobRect = recognizer.view.frame;
            [self setMagnify:YES fromRect:knobRect ratio:2 animated:animatePopover];
            
            // Scrolling
            tapPoint.y -= parent.contentOffset.y;
            [parent autoScrollForTouchAtPoint:tapPoint];
        }
    }
}

#pragma mark UIView Methods

- (id)initWithFrame:(CGRect)frame codeView:(ECCodeView *)codeView
{
    if ((self = [super initWithFrame:frame])) 
    {
        parent = codeView;
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    if (selection.length > 0) 
    {
        CGContextRef context = UIGraphicsGetCurrentContext();
        [selectionColor setFill];
        
        CGPoint rectsOrigin = selectionRects.bounds.origin;
        CGContextTranslateCTM(context, -rectsOrigin.x, -rectsOrigin.y);
        
        [selectionRects addRectsToContext:context];
        CGContextFillPath(context);
    }
    else
    {
        [caretColor setFill];
        UIRectFill(rect);
    }
}

@end

#pragma mark -
#pragma mark CodeInfoView

@implementation CodeInfoView

@synthesize parentSize, parentContentOffsetRatio;
@synthesize normalWidth, navigatorWidth;
@synthesize navigatorInsets, navigatorVisible, navigatorBackgroundColor;

- (id)initWithFrame:(CGRect)frame navigatorDatasource:(id<ECCodeViewDataSource>)source renderer:(ECTextRenderer *)aRenderer renderingQueue:(NSOperationQueue *)queue
{
    parentSize = [UIScreen mainScreen].bounds.size;
    normalWidth = 11;
    navigatorInsets = UIEdgeInsetsMake(5, 5, 5, 0);
    
    frame.origin.x += frame.size.width - normalWidth;
    frame.size.width = normalWidth;
    
    if ((self = [super initWithFrame:frame])) 
    {
        datasource = source;
        renderer = aRenderer;
        renderingQueue = queue;
        
        self.backgroundColor = [UIColor clearColor];
        
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tapRecognizer];
    }
    return self;
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
    
    if (!navigatorView) 
    {
        CGRect frame = (CGRect){ CGPointZero, parentSize };
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
        // TODO make this more effcient (like 4 subviews at corners)
        navigatorView.layer.cornerRadius = 3;
    }
    
    if (visible)
        [self addSubview:navigatorView];
    
    if (animated)
    {
        if (visible)
            navigatorVisible = YES;
        navigatorView.alpha = 0;
        [UIView animateWithDuration:0.25 delay:0 options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut) animations:^(void) {
            self.backgroundColor = visible ? navigatorBackgroundColor : [UIColor clearColor];
            navigatorView.alpha = visible;
        } completion:^(BOOL finished) {
            if (finished)
            {
                if (!visible) 
                {
                    navigatorVisible = NO;
                    [navigatorView removeFromSuperview];
                }
            }
        }];
    }
    else
    {
        navigatorVisible = visible;
        if (visible) 
        {
            navigatorView.alpha = 1;
            self.backgroundColor = navigatorBackgroundColor;
        }
        else
        {
            self.backgroundColor = [UIColor clearColor];
            [navigatorView removeFromSuperview];
        }
    }
}

- (void)updateNavigator
{    
    CGRect frame = self.bounds;
    frame.size.width = navigatorWidth;
    frame = UIEdgeInsetsInsetRect(frame, navigatorInsets);
    
    // Resetting the frame will trigger actual layout update
    navigatorView.frame = frame;
    [navigatorView setNeedsLayout];
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    // TODO manage search marks
//    [self setNavigatorVisible:!navigatorVisible animated:YES];
}

@end

#pragma mark -
#pragma mark ECCodeView

@implementation ECCodeView

#pragma mark -
#pragma mark Properties

@synthesize infoViewVisible;
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

@dynamic datasource;

- (void)setDatasource:(id<ECCodeViewDataSource>)aDatasource
{
    [super setDatasource:aDatasource];
    
    dataSourceHasCodeCanEditTextInRange = [self.datasource respondsToSelector:@selector(codeView:canEditTextInRange:)];
    dataSourceHasViewControllerForCompletionAtTextInRange = [self.datasource respondsToSelector:@selector(codeView:viewControllerForCompletionAtTextInRange:)];
}

- (void)setCaretColor:(UIColor *)caretColor
{
    selectionView.caretColor = caretColor;
}

- (UIColor *)caretColor
{
    return selectionView.caretColor;
}

- (void)setSelectionColor:(UIColor *)selectionColor
{
    selectionView.selectionColor = selectionColor;
}

- (UIColor *)selectionColor
{
    return selectionView.selectionColor;
}

#pragma mark NSObject Methods

static void preinit(ECCodeView *self)
{
//    self->navigatorBackgroundColor = [UIColor styleForegroundColor];
    self->navigatorWidth = 200;
}

static void init(ECCodeView *self)
{
    // Adding selection view
    self->selectionView = [[TextSelectionView alloc] initWithFrame:CGRectZero codeView:self];
//    [self->selectionView setCaretColor:[UIColor styleThemeColorOne]];
//    [self->selectionView setSelectionColor:[[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3]];
    [self->selectionView setOpaque:NO];
    [self->selectionView setHidden:YES];
    [self addSubview:self->selectionView];
    
    // Adding focus recognizer
    self->focusRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureFocus:)];
    [self->focusRecognizer setNumberOfTapsRequired:1];
    [self addGestureRecognizer:self->focusRecognizer];
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


- (void)layoutSubviews
{
    if (infoViewVisible) 
    {
        CGRect infoFrame = self.bounds;
        infoView.parentContentOffsetRatio = infoFrame.origin.y / (self.contentSize.height - infoFrame.size.height);
        
        CGFloat infoWidth = infoView.currentWidth;
        infoFrame.origin.x = infoFrame.size.width - infoWidth;
        infoFrame.size.width = infoWidth;        
        infoView.frame = infoFrame;
        
        [self sendSubviewToBack:infoView];
    }
    
    [super layoutSubviews];
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
            infoView = [[CodeInfoView alloc] initWithFrame:self.bounds navigatorDatasource:self.datasource renderer:renderer renderingQueue:renderingQueue];
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
        [infoView updateNavigator];
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
    navigatorBackgroundColor = color;
    infoView.navigatorBackgroundColor = color;
}

#pragma mark -
#pragma mark Completion

- (void)showCompletionPopoverAtCursor
{
    if (![self isFirstResponder])
        return;
    
    NSRange completionRange = selectionView.selection;
    if (completionRange.length == 0) 
    {
        ECTextPosition *cursorPosition = selectionView.selectionPosition;
        ECTextPosition *wordStart = (ECTextPosition *)[self.tokenizer positionFromPosition:cursorPosition toBoundary:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
        
        if (!wordStart)
            wordStart = cursorPosition;
        
        completionRange = NSMakeRange(wordStart.index, cursorPosition.index - wordStart.index);
    }
    
    [self showCompletionForTextInRange:completionRange];
}

- (void)showCompletionForTextInRange:(NSRange)textRange
{
    if (!dataSourceHasViewControllerForCompletionAtTextInRange)
        return;
    
    if (!completionPopover)
    {
        completionPopover = [[ECPopoverController alloc] initWithContentViewController:nil];
        completionPopover.automaticDismiss = YES;
    }
    
    completionPopover.contentViewController = [self.datasource codeView:self viewControllerForCompletionAtTextInRange:textRange];
    
    // TODO something if completionPopover.contentViewController is nil
    
    CGRect textRect = [renderer rectsForStringRange:textRange limitToFirstLine:YES].bounds;
    textRect.origin.x += textRect.size.width - 1;
    textRect.size.width = 2;
    [completionPopover presentPopoverFromRect:textRect inView:self permittedArrowDirections:UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown animated:YES];
}

#pragma mark -
#pragma mark UIResponder methods

- (BOOL)canBecomeFirstResponder
{
    // TODO should return depending on edit enabled state
    return dataSourceHasCodeCanEditTextInRange;
}

- (BOOL)becomeFirstResponder
{
    BOOL shouldBecomeFirstResponder = [super becomeFirstResponder];
    
    // Lazy create recognizers
    if (!tapRecognizer && shouldBecomeFirstResponder)
    {
        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTap:)];
        [self addGestureRecognizer:tapRecognizer];
        
        tapTwoTouchesRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureTapTwoTouches:)];
        tapTwoTouchesRecognizer.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:tapTwoTouchesRecognizer];
        
        doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureDoubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapRecognizer];
        
        longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureLongPress:)];
        [self addGestureRecognizer:longPressRecognizer];
        
        longDoublePressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureLongPress:)];
        longDoublePressRecognizer.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:longDoublePressRecognizer];
        
        // TODO initialize gesture recognizers
    }
    
    // Activate recognizers
    if (shouldBecomeFirstResponder)
    {
        focusRecognizer.enabled = NO;
        tapRecognizer.enabled = YES;
        tapTwoTouchesRecognizer.enabled = YES;
        doubleTapRecognizer.enabled = YES;
        longPressRecognizer.enabled = YES;
        longDoublePressRecognizer.enabled = YES;
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
        tapTwoTouchesRecognizer.enabled = NO;
        doubleTapRecognizer.enabled = NO;
        longPressRecognizer.enabled = NO;
        longDoublePressRecognizer.enabled = NO;
        
        // Remove selection
        selectionView.hidden = YES;
    }
    
    [self setNeedsLayout];
    
    // TODO call delegate's endediting
    
    return shouldResignFirstResponder;
}

#pragma mark -
#pragma mark UIKeyInput protocol

- (BOOL)hasText
{
    return [self.datasource textLength] > 0;
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
    if (!_tokenizer)
        _tokenizer = [[UITextInputStringTokenizer alloc] initWithTextInput:self];
    return _tokenizer;
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
        result = [self.datasource codeView:self stringInRange:(NSRange){s, e - s}];
    
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
    
    NSUInteger textLength = [self.datasource textLength];
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
    
    return [[ECTextRange alloc] initWithRange:markedRange];
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
    return [[ECTextRange alloc] initWithStart:(ECTextPosition *)fromPosition end:(ECTextPosition *)toPosition];
}

- (UITextPosition *)positionFromPosition:(UITextPosition *)position 
                                  offset:(NSInteger)offset
{
    return [self positionFromPosition:position inDirection:(UITextLayoutDirection)UITextStorageDirectionForward offset:offset];
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
    else
    {
        result = [renderer positionFromPosition:pos inLayoutDirection:direction offset:offset];
        if (result == NSUIntegerMax)
            return nil;
    }
    
    NSUInteger textLength = [self.datasource textLength];
    if (result > textLength)
        result = textLength;
    
    ECTextPosition *resultPosition = [[ECTextPosition alloc] initWithIndex:result];
    
    return resultPosition;
}

- (UITextPosition *)beginningOfDocument
{
    ECTextPosition *p = [[ECTextPosition alloc] initWithIndex:0];
    return p;
}

- (UITextPosition *)endOfDocument
{
    ECTextPosition *p = [[ECTextPosition alloc] initWithIndex:[self.datasource textLength]];
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
//    abort();
}

#pragma mark Geometry and Hit-Testing Methods

- (CGRect)firstRectForRange:(UITextRange *)range
{
    CGRect r = [renderer rectsForStringRange:[(ECTextRange *)range range] limitToFirstLine:YES].bounds;
    return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = [renderer rectsForStringRange:(NSRange){pos, 0} limitToFirstLine:YES].bounds;
    
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
    CGFloat scale = self.contentScaleFactor;
    if (scale != 1.0)
    {
        point.x /= scale;
        point.y /= scale;
    }
    
    NSUInteger location = [renderer closestStringLocationToPoint:point 
                                               withinStringRange:range ? [(ECTextRange *)range range] : (NSRange){0, 0}];
    return [[ECTextPosition alloc] initWithIndex:location];;
}

- (UITextRange *)characterRangeAtPoint:(CGPoint)point
{
    ECTextPosition *pos = (ECTextPosition *)[self closestPositionToPoint:point];
    
    NSRange r = [[self.datasource codeView:self stringInRange:(NSRange){ pos.index, 1 }] rangeOfComposedCharacterSequenceAtIndex:0];
    
    if (r.location == NSNotFound)
        return nil;
    
    return [[ECTextRange alloc] initWithRange:r];
}

#pragma mark - Editing Actions

- (void)copy:(id)sender
{
    if (selectionView.isEmpty)
        return;
    
    UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
    NSString *text = [self textInRange:selectionView.selectionRange];
    generalPasteboard.string = text;
}

- (void)cut:(id)sender
{
    if (selectionView.isEmpty)
        return;
    
    [self copy:sender];
    [self delete:sender];
}

- (void)delete:(id)sender
{
    if (selectionView.isEmpty)
        return;
    
    [inputDelegate textWillChange:self];
    [inputDelegate selectionWillChange:self];
    [self replaceRange:selectionView.selectionRange withText:@""];
    [inputDelegate textDidChange:self];
    [inputDelegate selectionDidChange:self];
}

- (void)paste:(id)sender
{
    // TODO smart paste logic
    
    NSString *text = [UIPasteboard generalPasteboard].string;
    if (!text)
        return;
    
    ECTextRange *selectedRange;
    if (selectionView.hasSelection && !selectionView.hidden)
        selectedRange = selectionView.selectionRange;
    else
        selectedRange = [ECTextRange textRangeWithRange:NSMakeRange([self.datasource textLength], 0)];
    
    [inputDelegate textWillChange:self];
    [inputDelegate selectionWillChange:self];
    [self replaceRange:selectedRange withText:text];
    [inputDelegate textDidChange:self];
    [inputDelegate selectionDidChange:self];
}

- (void)select:(id)sender
{
    ECTextRange *selectionRange = selectionView.selectionRange;
    UITextRange *forwardRange = [tokenizer rangeEnclosingPosition:selectionRange.start withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionForward];
    UITextRange *backRange = [tokenizer rangeEnclosingPosition:selectionRange.end withGranularity:UITextGranularityWord inDirection:UITextStorageDirectionBackward];
    
    if (forwardRange && backRange)
    {
        ECTextRange *range = [[ECTextRange alloc] initWithStart:(ECTextPosition *)backRange.start end:(ECTextPosition *)forwardRange.end];
        [self setSelectedTextRange:range];
    }
    else if (forwardRange)
    {
        [self setSelectedTextRange:forwardRange];
    }
    else if (backRange)
    {
        [self setSelectedTextRange:backRange];
    }
    else
    {
        // Not empty selection is not altered
        if (![selectionRange.start isEqual:selectionRange.end])
            return;
        
        // TODO instead of left/rigth text direction see oui
        UITextPosition *beforeStart = [self positionFromPosition:selectionRange.start inDirection:UITextLayoutDirectionLeft offset:1];
        if (beforeStart && [selectionRange.start isEqual:beforeStart] == NO)
        {
            self.selectedTextRange = [self textRangeFromPosition:beforeStart toPosition:selectionRange.start];
            return;
        }
        
        UITextPosition *afterEnd = [self positionFromPosition:selectionRange.end inDirection:UITextLayoutDirectionRight offset:1];
        if (afterEnd && [selectionRange.end isEqual:afterEnd] == NO)
        {
            self.selectedTextRange = [self textRangeFromPosition:selectionRange.end toPosition:afterEnd];
            return;
        }
    }
}

- (void)selectAll:(id)sender
{
    // TODO
}

- (void)complete:(id)sender
{
    [self showCompletionPopoverAtCursor];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(copy:) || action == @selector(cut:) || action == @selector(delete:))
    {
        return !selectionView.isEmpty;
    }
    
    if (action == @selector(paste:))
    {
        UIPasteboard *generalPasteboard = [UIPasteboard generalPasteboard];
        return [generalPasteboard containsPasteboardTypes:UIPasteboardTypeListString];
    }
    
    if (action == @selector(complete:))
    {
        return selectionView.hasSelection;
    }
    
    if (action == @selector(select:))
    {
        return selectionView.selection.length == 0;
    }
    
    if (action == @selector(selectAll:))
    {
        if (!selectionView.hasSelection)
            return YES;
        
        UITextRange *selectionRange = selectionView.selectionRange;
        if (![selectionRange.start isEqual:[self beginningOfDocument]] 
            || ![selectionRange.end isEqual:[self endOfDocument]])
            return YES;
    }
    
    return NO;
}


#pragma mark - Private methods

- (void)editDataSourceInRange:(NSRange)range withString:(NSString *)string
{
    if (dataSourceHasCodeCanEditTextInRange
        && [self.datasource codeView:self canEditTextInRange:range]) 
    {
        [self unmarkText];
        
        [inputDelegate textWillChange:self];
        
        [self.datasource codeView:self commitString:string forTextInRange:range];
        
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
    
    // Will automatically resize and position the selection view
    selectionView.selection = newSelection;
    
    if (shouldNotify)
        [inputDelegate selectionDidChange:self];
    
    // Position selection view
    if ([self isFirstResponder])
    {
        selectionView.hidden = NO;
        // TODO this has been removed because it was putting the selection view
        // on top of thumb handlers.
//        [self bringSubviewToFront:selectionView];
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
    
}

- (void)autoScrollForTouchAtPoint:(CGPoint)point
{
    CGRect bounds = self.bounds;
    
    // Stop old scrolling 
    if (touchScrollTimer) 
    {
        [touchScrollTimer invalidate];
        touchScrollTimer = nil;
    }
    
    // Get scrolling speed and direction
    CGFloat scrollingOffset = 0;
    // TODO parametrize scrolling area
    if (point.y < 50) 
    {
        scrollingOffset = point.y - 50;
    }
    else if (point.y > CGRectGetMaxY(bounds) - 50)
    {
        scrollingOffset = point.y - (CGRectGetMaxY(bounds) - 50);
    }
    
    // Schedule new scrolling timer if needed
    if (scrollingOffset != 0) 
    {
        touchScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/ 60.0 usingBlock:^(NSTimer *timer) {
            CGFloat contentOffset = self.contentOffset.y;
            
            // Invalidate timer if reaging content limits
            if (contentOffset <= 0 || contentOffset >= (self.contentSize.height - self.bounds.size.height)) 
            {
                [touchScrollTimer invalidate];
                touchScrollTimer = nil;
            }
            else
            {
                contentOffset += scrollingOffset;
                [self scrollRectToVisible:CGRectMake(0, contentOffset, 1, 1) animated:NO];
            }
        } repeats:YES];
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
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    [sharedMenuController setMenuVisible:NO animated:YES];
    
    CGPoint tapPoint = [recognizer locationInView:self];
    [self setSelectedTextFromPoint:tapPoint toPoint:tapPoint];
}

- (void)handleGestureTapTwoTouches:(UITapGestureRecognizer *)recognizer
{
    UIMenuController *sharedMenuController = [UIMenuController sharedMenuController];
    
    // Adding custom menu
    UIMenuItem *completionMenuItem = [[UIMenuItem alloc] initWithTitle:@"Completion" action:@selector(complete:)];
    sharedMenuController.menuItems = [NSArray arrayWithObject:completionMenuItem];
    
    // Show context menu
    [sharedMenuController setTargetRect:selectionView.frame inView:self];
    [sharedMenuController setMenuVisible:YES animated:YES];
}

- (void)handleGestureDoubleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint tapPoint = [recognizer locationInView:self];
    ECTextRange *sel = (ECTextRange *)[self.tokenizer rangeEnclosingPosition:[self closestPositionToPoint:tapPoint] withGranularity:UITextGranularityWord inDirection:UITextLayoutDirectionLeft];
    [self setSelectedTextRange:sel];
}

- (void)handleGestureLongPress:(UILongPressGestureRecognizer *)recognizer
{
    BOOL multiTouch = NO;
    CGPoint tapPoint = [recognizer locationOfTouch:0 inView:self];
    CGPoint secondTapPoint = tapPoint;
    if ([recognizer numberOfTouches] > 1) 
    {
        secondTapPoint = [recognizer locationOfTouch:1 inView:self];
        multiTouch = YES;
    }
    
    BOOL animatePopover = NO;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateEnded:
            [self setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
        case UIGestureRecognizerStateCancelled:
            selectionView.magnify = NO;
            break;
            
        case UIGestureRecognizerStateBegan:
            animatePopover = YES;
            
        default:
        {
            if (CGPointEqualToPoint(tapPoint, CGPointZero)) 
            {
                selectionView.magnify = NO;
                // TODO fix this?
                [self setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
                return;
            }
            
            // Set selection
            if (multiTouch) 
            {
                [self setSelectedTextFromPoint:tapPoint toPoint:secondTapPoint];
            }
            else
            {
                selectionView.selection = NSMakeRange([renderer closestStringLocationToPoint:tapPoint withinStringRange:(NSRange){0, 0}], 0);
                [selectionView setMagnify:YES fromRect:selectionView.frame ratio:2 animated:animatePopover];
            }

            // Scrolling
            tapPoint.y -= self.contentOffset.y;
            [self autoScrollForTouchAtPoint:tapPoint];
        }
    }
}

@end
