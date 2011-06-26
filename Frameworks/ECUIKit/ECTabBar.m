//
//  ECTabBar.m
//  ACUI
//
//  Created by Nicola Peduzzi on 22/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECTabBar.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImage+BlockDrawing.h"
#import "NSTimer+block.h"
#import <objc/runtime.h>

@interface ECTabBar () {
@private
    NSMutableArray *tabButtons;
    
    CAGradientLayer *leftFadeLayer;
    CAGradientLayer *rightFadeLayer;
    
    UIView *additionalButtonsContainerView;
    
    __weak UIButton *movedTab;
    CGPoint movedTabOffsetFromCenter;
    NSUInteger movedTabIndex, movedTabDestinationIndex;
    NSTimer *movedTabScrollTimer;
    
    struct {
        unsigned int hasWillAddTabButtonAtIndex : 1;
        unsigned int hasDidAddTabButtonAtIndex : 1;
        unsigned int hasWillRemoveTabButtonAtIndex : 1;
        unsigned int hasDidRemoveTabButtonAtIndex : 1;
        unsigned int hasWillSelectTabAtIndex :1;
        unsigned int hasDidSelectTabAtIndex : 1;
        unsigned int hasWillMoveTabButton : 1;
        unsigned int hasDidMoveTabButtonFromIndexToIndex : 1;
    } delegateFlags;
}

- (void)tabButtonAction:(id)sender;
- (void)moveTabAction:(UILongPressGestureRecognizer *)recognizer;

@end

@implementation ECTabBar

#pragma mark - Properties

@synthesize tabButtonSize, buttonsInsets;
@synthesize delegate, longPressGestureRecognizer;
@synthesize selectedTabButton;

- (void)setDelegate:(id<ECTabBarDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateFlags.hasWillAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:willAddTabButton:atIndex:)];
    delegateFlags.hasDidAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:didAddTabButtonAtIndex:)];
    delegateFlags.hasWillRemoveTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:willRemoveTabButtonAtIndex:)];
    delegateFlags.hasDidRemoveTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:didRemoveTabButtonAtIndex:)];
    delegateFlags.hasWillSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:willSelectTabAtIndex:)];
    delegateFlags.hasDidSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:didSelectTabAtIndex:)];
    delegateFlags.hasWillMoveTabButton = [delegate respondsToSelector:@selector(tabBar:willMoveTabButton:)];
    delegateFlags.hasDidMoveTabButtonFromIndexToIndex = [delegate respondsToSelector:@selector(tabBar:didMoveTabButton:fromIndex:toIndex:)];
}

@synthesize closeTabImage;

- (NSUInteger)tabCount
{
    return [tabButtons count];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    
    // TODO this objc_unretainedObject([backgroundColor colorWithAlphaComponent:0].CGColor) may cause problems?
    leftFadeLayer.colors = [NSArray arrayWithObjects:
                            objc_unretainedObject(backgroundColor.CGColor),
                            objc_unretainedObject([backgroundColor colorWithAlphaComponent:0].CGColor), nil];
    rightFadeLayer.colors = [NSArray arrayWithObjects:
                             objc_unretainedObject([backgroundColor colorWithAlphaComponent:0].CGColor),
                             objc_unretainedObject(backgroundColor.CGColor), nil];
    
    additionalButtonsContainerView.backgroundColor = self.backgroundColor;
}

@synthesize additionalControls, additionalControlsDefaultSize;

- (void)setAdditionalControls:(NSArray *)array
{
    additionalControls = array;
    
    if (!additionalControls)
    {
        [additionalButtonsContainerView removeFromSuperview];
        additionalButtonsContainerView = nil;
        return;
    }
    
    if (!additionalButtonsContainerView)
    {
        additionalButtonsContainerView = [UIView new];
        additionalButtonsContainerView.backgroundColor = self.backgroundColor;
        [self addSubview:additionalButtonsContainerView];
    }
    else
    {
        for (UIView *view in additionalButtonsContainerView.subviews)
        {
            [view removeFromSuperview];
        }
    }
    
    CGRect viewFrame;
    CGPoint defaultOrigin = CGPointMake(self.contentInset.left, 0);
    CGSize defaultSize = CGSizeMake(additionalControlsDefaultSize.width, additionalControlsDefaultSize.height ? additionalControlsDefaultSize.height : self.frame.size.height);
    for (UIView *view in additionalControls)
    {
        viewFrame = [view frame];
        if (CGRectIsEmpty(viewFrame))
            viewFrame.size = defaultSize;
        
        viewFrame.origin = defaultOrigin;
        defaultOrigin.x += viewFrame.size.width;
        
        view.frame = UIEdgeInsetsInsetRect(viewFrame, buttonsInsets);
        
        [additionalButtonsContainerView addSubview:view];
    }
    
    additionalButtonsContainerView.frame = (CGRect){ CGPointZero, CGSizeMake(defaultOrigin.x, self.frame.size.height) };
    
    UIEdgeInsets contentInset = self.contentInset;
    contentInset.right = defaultOrigin.x;
    self.contentInset = contentInset;
    
    [self setNeedsLayout];
}

#pragma mark - View Lifecicle

static void updateFadeViews(ECTabBar *self)
{    
    // Update left fade layer
    if (!self->leftFadeLayer)
    {
        self->leftFadeLayer = [CAGradientLayer layer];
        self->leftFadeLayer.anchorPoint = CGPointMake(0, 0);
        self->leftFadeLayer.bounds = CGRectMake(0, 0, 20, self.frame.size.height);
        self->leftFadeLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"position"];
        self->leftFadeLayer.startPoint = CGPointMake(0, .5);
        self->leftFadeLayer.endPoint = CGPointMake(1, .5);
        self->leftFadeLayer.opacity = 0;
    }
    
    // Update right fade layer
    if (!self->rightFadeLayer)
    {
        self->rightFadeLayer = [CAGradientLayer layer];
        self->rightFadeLayer.anchorPoint = CGPointMake(0, 0);
        self->rightFadeLayer.bounds = CGRectMake(0, 0, 20, self.frame.size.height);
        self->rightFadeLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"position"];
        self->rightFadeLayer.startPoint = CGPointMake(0, .5);
        self->rightFadeLayer.endPoint = CGPointMake(1, .5);
        self->rightFadeLayer.opacity = 0;
    }
}

static void preinit(ECTabBar *self)
{
    self->tabButtonSize = CGSizeMake(300, 0);
    self->buttonsInsets = UIEdgeInsetsMake(7, 0, 7, 7);
    self->additionalControlsDefaultSize = CGSizeMake(41, 0);
}

static void init(ECTabBar *self)
{
    self.contentInset = UIEdgeInsetsMake(0, 7, 0, 0);
    
    //
    self->longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moveTabAction:)];
    [self addGestureRecognizer:self->longPressGestureRecognizer];
    
    //
    [self setShowsVerticalScrollIndicator:NO];
    [self setShowsHorizontalScrollIndicator:NO];
    
    //
    updateFadeViews(self);
    [self setNeedsLayout];
}

- (id)initWithFrame:(CGRect)frame
{
    preinit(self);
    if ((self = [super initWithFrame:frame]))
    {
        init(self);
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    preinit(self);
    if ((self = [super initWithCoder:coder]))
    {
        init(self);       
    }
    return self;
}

- (void)layoutSubviews
{
    CGRect bounds = self.bounds;
    
    // Determine button's size
    CGRect buttonFrame = (CGRect) { CGPointZero, tabButtonSize };
    if (buttonFrame.size.height == 0)
        buttonFrame.size.height = bounds.size.height;
    
    // Layout tab button
    NSUInteger buttonIndex = 0;
    for (UIButton *button in tabButtons)
    {
        if (movedTab && buttonIndex == movedTabDestinationIndex && movedTabIndex > movedTabDestinationIndex)
            buttonFrame.origin.x += buttonFrame.size.width;
        
        if (button != movedTab)
        {
            button.frame = UIEdgeInsetsInsetRect(buttonFrame, buttonsInsets);
            buttonFrame.origin.x += buttonFrame.size.width;
        }
        
        if (movedTab && buttonIndex == movedTabDestinationIndex && movedTabIndex <= movedTabDestinationIndex)
            buttonFrame.origin.x += buttonFrame.size.width;
        
        ++buttonIndex;
    }
    
    // Layout additional buttons
    CGFloat rightMargin = 0;
    if (additionalButtonsContainerView)
    {
        CGRect containerFrame = additionalButtonsContainerView.frame;
        additionalButtonsContainerView.frame = (CGRect){ CGPointMake(CGRectGetMaxX(bounds) - containerFrame.size.width, bounds.origin.y) ,containerFrame.size };
        [self bringSubviewToFront:additionalButtonsContainerView];
        
        rightMargin = containerFrame.size.width;
    }
    
    // Show left fading layer
    if (bounds.origin.x > 0)
    {
        [self.layer addSublayer:leftFadeLayer];
        leftFadeLayer.position = bounds.origin;
        leftFadeLayer.opacity = 1;
    }
    else
    {
        leftFadeLayer.opacity = 0;
        [leftFadeLayer removeFromSuperlayer];
    }
    
    // Show right fading layer
    if (CGRectGetMaxX(bounds) < self.contentSize.width)
    {
        [self.layer addSublayer:rightFadeLayer];
        rightFadeLayer.position = CGPointMake(CGRectGetMaxX(bounds) - rightFadeLayer.bounds.size.width - rightMargin, bounds.origin.y);
        rightFadeLayer.opacity = 1;
    }
    else
    {
        rightFadeLayer.opacity = 0;
        [rightFadeLayer removeFromSuperlayer];
    }
}

#pragma mark - Managing Tabs

- (NSUInteger)selectedTabIndex
{
    return [tabButtons indexOfObject:selectedTabButton];
}

- (void)setSelectedTabIndex:(NSUInteger)index
{
    if (index >= [tabButtons count])
        return;
    
    if (index != NSNotFound)
        [selectedTabButton setSelected:NO];
    
    selectedTabButton = [tabButtons objectAtIndex:index];
    
    [selectedTabButton setSelected:YES];
    
    // Scroll to fully show tab
    CGRect selectedTabFrame = selectedTabButton.frame;
    selectedTabFrame.origin.x -= buttonsInsets.left;
    selectedTabFrame.size.width += buttonsInsets.left + buttonsInsets.right;
    [self scrollRectToVisible:selectedTabFrame animated:YES];
}

- (void)addTabButtonWithTitle:(NSString *)title animated:(BOOL)animated
{
    if (!tabButtons)
        tabButtons = [NSMutableArray new];
    
    // TODO use a +tabButtonClass
    NSUInteger newTabButtonIndex = [tabButtons count];
    UIButton *newTabButton = [UIButton new];
    
    CGRect buttonFrame = (CGRect) { CGPointZero, tabButtonSize };
    if (buttonFrame.size.height == 0)
        buttonFrame.size.height = self.frame.size.height;
    newTabButton.frame = UIEdgeInsetsInsetRect(buttonFrame, buttonsInsets);
    
    [newTabButton setTitle:title forState:UIControlStateNormal];
    [newTabButton addTarget:self action:@selector(tabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if (delegateFlags.hasWillAddTabButtonAtIndex 
        && ![delegate tabBar:self willAddTabButton:newTabButton atIndex:newTabButtonIndex])
        return;
    
    // Add the button and resize content
    [tabButtons addObject:newTabButton];
    self.contentSize = CGSizeMake(tabButtonSize.width * (newTabButtonIndex + 1), self.frame.size.height);
    
    // TODO animate
    [self addSubview:newTabButton];
    
    if (delegateFlags.hasDidAddTabButtonAtIndex)
        [delegate tabBar:self didAddTabButtonAtIndex:newTabButtonIndex];
}

- (void)removeTabAtIndex:(NSUInteger)index animated:(BOOL)animated
{
    if (index >= [tabButtons count])
        return;
    
    if (delegateFlags.hasWillRemoveTabButtonAtIndex
        && ![delegate tabBar:self willRemoveTabButtonAtIndex:index])
        return;
    
    if (animated)
    {
        UIButton *buttonToRemove = [tabButtons objectAtIndex:index];
        buttonToRemove.layer.shouldRasterize = YES;
        [UIView animateWithDuration:.10 animations:^(void) {
            buttonToRemove.alpha = 0;
        } completion:^(BOOL finished) {
            [buttonToRemove removeFromSuperview];
            [tabButtons removeObjectAtIndex:index];
            [UIView animateWithDuration:.15 animations:^(void) {
                [self layoutSubviews];
            } completion:^(BOOL finished) {
                CGSize contentSize = self.contentSize;
                contentSize.width -= tabButtonSize.width;
                self.contentSize = contentSize;
                
                if (delegateFlags.hasDidRemoveTabButtonAtIndex)
                    [delegate tabBar:self didRemoveTabButtonAtIndex:index];
            }];
        }];
    }
    else
    {
        [[tabButtons objectAtIndex:index] removeFromSuperview];
        [tabButtons removeObjectAtIndex:index];
        [self setNeedsLayout];
        
        CGSize contentSize = self.contentSize;
        contentSize.width -= tabButtonSize.width;
        self.contentSize = contentSize;
        
        if (delegateFlags.hasDidRemoveTabButtonAtIndex)
            [delegate tabBar:self didRemoveTabButtonAtIndex:index];
    }
}

- (UIButton *)tabAtIndex:(NSUInteger)index
{
    if (index >= [tabButtons count])
        return nil;
    
    return [tabButtons objectAtIndex:index];
}

- (NSUInteger)indexOfTab:(UIButton *)tabButton
{
    return [tabButtons indexOfObject:tabButton];
}

#pragma mark -

- (void)tabButtonAction:(id)sender
{
    NSUInteger tabIndex = [tabButtons indexOfObject:sender];
    
    if (tabIndex == NSNotFound)
        return;
    
    if (delegateFlags.hasWillSelectTabAtIndex
        && ![delegate tabBar:self willSelectTabAtIndex:tabIndex])
        return;
    
    [self setSelectedTabIndex:tabIndex];
    
    if (delegateFlags.hasDidSelectTabAtIndex)
        [delegate tabBar:self didSelectTabAtIndex:tabIndex];
}

- (void)moveTabAction:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            // Ignore long press in additional buttons
            CGPoint locationInView = [recognizer locationInView:self];
            if (additionalButtonsContainerView 
                && locationInView.x - self.contentOffset.x >= self.frame.size.width - additionalButtonsContainerView.frame.size.width)
            {
                movedTab = nil;
                return;
            }
            
            // Get tab to move and forward to delegate to ask for permission
            movedTabIndex = (NSUInteger)(locationInView.x / tabButtonSize.width);
            movedTabDestinationIndex = movedTabIndex;
            movedTab = [tabButtons objectAtIndex:movedTabIndex];
            if (delegateFlags.hasWillMoveTabButton
                && ![delegate tabBar:self willMoveTabButton:movedTab])
            {
                movedTab = nil;
                return;
            }
            
            // Record center offset and animate motion beginning
            movedTabOffsetFromCenter = CGPointMake(movedTab.center.x - locationInView.x, 0);
            [self bringSubviewToFront:movedTab];
            [UIView animateWithDuration:0.2 animations:^(void) {
                [movedTab setTransform:CGAffineTransformMakeScale(1.25, 1.25)];
                [movedTab setAlpha:0.75];
            }];
            
            break;
        }
            
        case UIGestureRecognizerStateChanged:
            if (movedTab)
            {
                CGPoint locationInView = [recognizer locationInView:self];
                
                // Move tab horizontaly
                CGPoint movedTabCenter = movedTab.center;
                movedTabCenter.x = locationInView.x + movedTabOffsetFromCenter.x;
                movedTab.center = movedTabCenter;
                
                // Select final destination
                movedTabDestinationIndex = (NSUInteger)(locationInView.x / tabButtonSize.width);
                if (movedTabDestinationIndex >= [tabButtons count])
                    movedTabDestinationIndex = [tabButtons count] - 1;
                [UIView animateWithDuration:0.2 animations:^(void) {
                    [self layoutSubviews];
                }];
                
                // Calculate scrolling offset
                CGPoint contentOffset = self.contentOffset;
                CGFloat scrollLocationInView = locationInView.x - contentOffset.x;
                CGFloat scrollingOffset = 0;
                if (scrollLocationInView < 60)
                    scrollingOffset = -(scrollLocationInView);
                else if (scrollLocationInView > self.frame.size.width - 60)
                    scrollingOffset = scrollLocationInView - (self.frame.size.width - 60);
                
                // Manual scrolling
                [movedTabScrollTimer invalidate];
                if (scrollingOffset != 0)
                    movedTabScrollTimer = [NSTimer scheduledTimerWithTimeInterval:1./100. usingBlock:^(NSTimer *timer) {
                        CGFloat contentOffsetX = self.contentOffset.x;
                        if ((scrollingOffset < 0 && contentOffsetX <= 0)
                            || (scrollingOffset > 0 && contentOffsetX > (self.contentSize.width - self.frame.size.width + self.contentInset.right)))
                        {
                            [movedTabScrollTimer invalidate];
                            movedTabScrollTimer = nil;
                        }
                        else
                        {
                            contentOffsetX += (scrollingOffset > 0 ? 5 : -5);
                            
                            CGPoint center = movedTab.center;
                            center.x -= self.contentOffset.x;

                            // TODO choose a better rect
                            [self scrollRectToVisible:CGRectMake(contentOffsetX, 0, self.frame.size.width - self.contentInset.right, 1) animated:NO];
                            
                            center.x += self.contentOffset.x;
                            movedTab.center = center;
                        }
                    } repeats:YES];
                else
                    movedTabScrollTimer = nil;
            }
            break;
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
            if (movedTab)
            {
                // Stop scrolling timer
                [movedTabScrollTimer invalidate];
                movedTabScrollTimer = nil;
                
                // Apply movement
                if (movedTabIndex != movedTabDestinationIndex)
                {
                    [tabButtons removeObjectAtIndex:movedTabIndex];
                    [tabButtons insertObject:movedTab atIndex:movedTabDestinationIndex];
                }
                
                // Animate to position
                UIButton *movedTabButton = movedTab;
                [UIView animateWithDuration:0.2 animations:^(void) {
                    [movedTab setTransform:CGAffineTransformIdentity];
                    [movedTab setAlpha:1.0];
                    movedTab = nil;
                    [self layoutSubviews];
                } completion:^(BOOL finished) {
                    [self sendSubviewToBack:movedTab];
                    
                    if (delegateFlags.hasDidMoveTabButtonFromIndexToIndex)
                        [delegate tabBar:self didMoveTabButton:movedTabButton fromIndex:movedTabIndex toIndex:movedTabDestinationIndex];
                }];
            }
            break;
            
        default:
            break;
    }
}

@end
