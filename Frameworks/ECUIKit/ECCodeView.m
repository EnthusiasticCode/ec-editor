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
#import "UIColor+StyleColors.h"
#import "NSTimer+block.h"

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
    NSRange markedRange;
    
    // Touch scrolling timer
    NSTimer *touchScrollTimer;
    
    // Recognizers
    UITapGestureRecognizer *focusRecognizer;
    UITapGestureRecognizer *tapRecognizer;
    UITapGestureRecognizer *doubleTapRecognizer;
    UILongPressGestureRecognizer *longPressRecognizer;
    UILongPressGestureRecognizer *longDoublePressRecognizer;
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

// Gestures handlers
- (void)handleGestureFocus:(UITapGestureRecognizer *)recognizer;
- (void)handleGestureTap:(UITapGestureRecognizer *)recognizer;
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
@property (nonatomic, retain) UIColor *caretColor;

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
@property (nonatomic, assign) ECTextRange *selectionRange;
@property (nonatomic, readonly) ECTextPosition *selectionPosition;

#pragma mark Selection Styles

@property (nonatomic, retain) UIColor *selectionColor;
@property (nonatomic, retain) UIColor *caretColor;
@property (nonatomic, getter = isBlinking) BOOL blink;

#pragma mark Magnification

@property (nonatomic, getter = isMagnifying) BOOL magnify;
@property (nonatomic, readonly) ECPopoverController *magnificationPopover;
@property (nonatomic, readonly) TextMagnificationView *magnificationView;

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

@property (nonatomic, retain) UIColor *navigatorBackgroundColor;

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

- (void)dealloc
{
    [detailImage release];
    [super dealloc];
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
    [parent.renderingQueue addOperationWithBlock:^(void) {
        UIGraphicsBeginImageContext(self.bounds.size);
        // Prepare magnified context
        CGContextRef imageContext = UIGraphicsGetCurrentContext();        
        CGContextScaleCTM(imageContext, magnification, magnification);
        CGContextTranslateCTM(imageContext, -textRect.origin.x, 0);
        // Render text
        CGContextSaveGState(imageContext);
        [parent.renderer drawTextWithinRect:textRect inContext:imageContext];
        CGContextRestoreGState(imageContext);
        // Render additional drawings
        if (block)
            block(imageContext, textRect.origin);
        // Get result image
        @synchronized(detailImage)
        {
            [detailImage release];
            detailImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
        }
        UIGraphicsEndImageContext();
        // Request rerendering
        [[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
            [self setNeedsDisplay];
        }];
    }];
}

@end

#pragma mark -
#pragma mark TextSelectionKnobView

@implementation TextSelectionKnobView

@synthesize knobDirection, knobDiameter;
@synthesize caretRect, caretColor;

- (void)setCaretRect:(CGRect)rect
{
    caretRect = rect;
    
    // Set frame considering knob direction
    rect.size.width = knobDiameter;
    rect.origin.x -= knobDiameter / 2;
    rect.size.height += knobDiameter;
    if (knobDirection == UITextLayoutDirectionLeft || knobDirection == UITextLayoutDirectionUp) 
    {
        rect.origin.y -= knobDiameter;
    }
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

- (void)dealloc
{
    [caretColor release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    [caretColor setFill];
    
    // Draw caret
    CGRect caret = caretRect;
    caret.origin.x = CGRectGetMidX(self.bounds) - CARET_WIDTH / 2;
    caret.origin.y = 0;
    if (knobDirection == UITextLayoutDirectionLeft)
        caret.origin.y += knobDiameter;
    UIRectFill(caret);
    
    // Draw knob
    CGRect knobRect = CGRectMake(0, 0, knobDiameter, knobDiameter);
    if (knobDirection == UITextLayoutDirectionRight)
        knobRect.origin.y += caretRect.size.height;
    [[UIBezierPath bezierPathWithRoundedRect:knobRect cornerRadius:1] fill];
}

@end

#pragma mark -
#pragma mark TextSelectionView

@implementation TextSelectionView

#pragma mark Properties

@synthesize selection;
@synthesize selectionColor;
@synthesize caretColor;
@synthesize blink;

- (void)setSelection:(NSRange)range
{
    if (NSEqualRanges(range, selection))
        return;
    
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
        UIEdgeInsets parentTextInsets = parent.textInsets;
        
        [selectionRects release];
        selectionRects = [[parent.renderer rectsForStringRange:selection limitToFirstLine:NO] retain];
        frame = selectionRects.bounds;
        frame.origin.x += parentTextInsets.left;
        frame.origin.y += parentTextInsets.top;
        
        // Left knob
        if (!leftKnob) 
        {
            leftKnob = [TextSelectionKnobView new];
            leftKnob.caretColor = caretColor;
            leftKnob.knobDirection = UITextLayoutDirectionLeft;
        }
        // TODO!!! set knob 'caret'
        CGRect knobRect = [selectionRects topLeftRect];
        knobRect.origin.x += parentTextInsets.left;
        knobRect.origin.y += parentTextInsets.top;
        knobRect.size.width = CARET_WIDTH;
        leftKnob.caretRect = knobRect;
        [parent addSubview:leftKnob];
        if (!leftKnobRecognizer) 
        {
            leftKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
            leftKnobRecognizer.minimumPressDuration = 0;
            [leftKnob addGestureRecognizer:leftKnobRecognizer];
            [leftKnobRecognizer release];
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
        knobRect.origin.x = CGRectGetMaxX(knobRect) + parentTextInsets.left;
        knobRect.origin.y += parentTextInsets.top;
        knobRect.size.width = CARET_WIDTH;
        rightKnob.caretRect = knobRect;
        [parent addSubview:rightKnob];
        if (!rightKnobRecognizer) 
        {
            rightKnobRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleKnobGesture:)];
            rightKnobRecognizer.minimumPressDuration = 0;
            [rightKnob addGestureRecognizer:rightKnobRecognizer];
            [rightKnobRecognizer release];
        }
        rightKnobRecognizer.enabled = YES;
    }
    self.frame = frame;
    
    [self setNeedsDisplay];
}

- (ECTextRange *)selectionRange
{
    return [[[ECTextRange alloc] initWithRange:selection] autorelease];
}

- (void)setSelectionRange:(ECTextRange *)selectionRange
{
    self.selection = [selectionRange range];
}

- (ECTextPosition *)selectionPosition
{
    return [[[ECTextPosition alloc] initWithIndex:selection.location] autorelease];
}

#pragma mark Blinking

- (void)setBlink:(BOOL)doBlink
{
    if (blink == doBlink)
        return;
    
    blink = doBlink;
    
    if (!blinkAnimation) 
    {
        blinkAnimation = [[CABasicAnimation animationWithKeyPath:@"opacity"] retain];
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
        UIEdgeInsets parentTextInsets = parent.textInsets;
        CGPoint textPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        textPoint.x -= parentTextInsets.left;
        textPoint.y -= parentTextInsets.top;
        [self.magnificationView detailTextAtPoint:textPoint magnification:ratio additionalDrawingBlock:^(CGContextRef context, CGPoint textOffset) {
            if (selection.length == 0) 
            {
                // Draw caret
                CGRect detailCaretRect = self.frame;
                detailCaretRect.origin.x -= parentTextInsets.left;
                detailCaretRect.origin.y -= parentTextInsets.top + textOffset.y;
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
        
        [detail release];
    }
    return magnificationPopover;
}

- (TextMagnificationView *)magnificationView
{
    return (TextMagnificationView *)self.magnificationPopover.popoverView.contentView;
}

- (void)handleKnobGesture:(UILongPressGestureRecognizer *)recognizer
{    
    UIEdgeInsets parentTextInsets = parent.textInsets;
    CGPoint tapPoint = [recognizer locationInView:parent];
    CGPoint textPoint = tapPoint;
    
    // Adding knob offset
    if (recognizer.view == rightKnob)
    {
        if (textPoint.y <= CGRectGetMidY(leftKnob.caretRect))
            textPoint.y = CGRectGetMidY(rightKnob.caretRect);
        else if (textPoint.y > CGRectGetMaxY(rightKnob.caretRect))
            textPoint.y -= MIN(rightKnob.caretRect.size.height, rightKnob.knobDiameter);
    }
    else // leftKnob
    {
        if (textPoint.y >= CGRectGetMidY(rightKnob.caretRect))
            textPoint.y = CGRectGetMidY(leftKnob.caretRect);
        else if (textPoint.y < leftKnob.caretRect.origin.y)
            textPoint.y += MIN(leftKnob.caretRect.size.height, leftKnob.knobDiameter);
    }
    textPoint.x -= parentTextInsets.left;
    textPoint.y -= parentTextInsets.top;
    
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
            [self setMagnify:YES fromRect:[(TextSelectionKnobView *)recognizer.view caretRect] ratio:2 animated:animatePopover];
            
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

- (void)dealloc
{
    [blinkAnimation release];
    
    [selectionColor release];
    [caretColor release];
    
    [selectionRects release];
    [leftKnob release];
    [rightKnob release];
    
    [magnificationPopover release];
    
    [super dealloc];
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

#pragma mark NSObject Methods

static void preinit(ECCodeView *self)
{
    self->navigatorBackgroundColor = [[UIColor styleForegroundColor] retain];
    self->navigatorWidth = 200;
}

static void init(ECCodeView *self)
{
    // Adding selection view
    self->selectionView = [[TextSelectionView alloc] initWithFrame:CGRectZero codeView:self];
    [self->selectionView setCaretColor:[UIColor styleThemeColorOne]];
    [self->selectionView setSelectionColor:[[UIColor styleThemeColorOne] colorWithAlphaComponent:0.3]];
    [self->selectionView setOpaque:NO];
    [self->selectionView setHidden:YES];
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
    [navigatorBackgroundColor release];
    [infoView release];
    [super dealloc];
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
        
        doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureDoubleTap:)];
        doubleTapRecognizer.numberOfTapsRequired = 2;
        [self addGestureRecognizer:doubleTapRecognizer];
        [doubleTapRecognizer release];
        
        longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureLongPress:)];
        [self addGestureRecognizer:longPressRecognizer];
        [longPressRecognizer release];
        
        longDoublePressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureLongPress:)];
        longDoublePressRecognizer.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:longDoublePressRecognizer];
        [longDoublePressRecognizer release];
        
        // TODO initialize gesture recognizers
    }
    
    // Activate recognizers
    if (shouldBecomeFirstResponder)
    {
        focusRecognizer.enabled = NO;
        tapRecognizer.enabled = YES;
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
    else
    {
        result = [renderer positionFromPosition:pos inLayoutDirection:direction offset:offset];
        if (result == NSUIntegerMax)
            return nil;
    }
    
    NSUInteger textLength = [self.datasource textLength];
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
    ECTextPosition *p = [[[ECTextPosition alloc] initWithIndex:[self.datasource textLength]] autorelease];
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
    CGRect r = [renderer rectsForStringRange:[(ECTextRange *)range range] limitToFirstLine:YES].bounds;
    return r;
}

- (CGRect)caretRectForPosition:(UITextPosition *)position
{
    NSUInteger pos = ((ECTextPosition *)position).index;
    CGRect carretRect = [renderer rectsForStringRange:(NSRange){pos, 0} limitToFirstLine:YES].bounds;
    
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
    
    NSRange r = [[self.datasource codeView:self stringInRange:(NSRange){ pos.index, 1 }] rangeOfComposedCharacterSequenceAtIndex:0];
    
    if (r.location == NSNotFound)
        return nil;
    
    return [[[ECTextRange alloc] initWithRange:r] autorelease];
}

#pragma mark -
#pragma mark Private methods

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
    CGPoint tapPoint = [recognizer locationInView:self];
    [self setSelectedTextFromPoint:tapPoint toPoint:tapPoint];
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
                CGPoint textPoint = tapPoint;
                textPoint.x -= textInsets.left;
                textPoint.y -= textInsets.top;
                selectionView.selection = NSMakeRange([renderer closestStringLocationToPoint:textPoint withinStringRange:(NSRange){0, 0}], 0);
                [selectionView setMagnify:YES fromRect:selectionView.frame ratio:2 animated:animatePopover];
            }

            // Scrolling up
//            // TODO get top point offset if mutlitouch
//            CGPoint offset = self.contentOffset;
//            CGFloat topScroll = 50 - tapPoint.y + offset.y;
//            if (topScroll > 0)
//            {
//                offset.y -= topScroll;
//                [self scrollRectToVisible:(CGRect){ {0, offset.y }, {1, 1} } animated:NO];
//                [self performSelector:@selector(handleGestureLongPress:) withObject:recognizer afterDelay:0.1];
//            }
            tapPoint.y -= self.contentOffset.y;
            [self autoScrollForTouchAtPoint:tapPoint];
        }
    }
}

@end
