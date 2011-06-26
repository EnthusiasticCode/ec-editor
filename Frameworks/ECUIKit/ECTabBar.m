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
#import <objc/runtime.h>

@interface ECTabBar () {
@private
    NSMutableArray *tabButtons;
    
    CAGradientLayer *leftFadeLayer;
    CAGradientLayer *rightFadeLayer;
    
    UIView *additionalButtonsContainerView;
    
    struct {
        unsigned int hasWillAddTabButtonAtIndex : 1;
        unsigned int hasDidAddTabButtonAtIndex : 1;
        unsigned int hasWillRemoveTabButtonAtIndex : 1;
        unsigned int hasDidRemoveTabButtonAtIndex : 1;
        unsigned int hasWillSelectTabAtIndex :1;
        unsigned int hasDidSelectTabAtIndex : 1;
        unsigned int hasWillMoveTabFromIndexToIndex : 1;
        unsigned int reserved : 1;
    } delegateFlags;
}

- (void)tabButtonAction:(id)sender;
- (void)moveTabAction:(UILongPressGestureRecognizer *)recognizer;

@end

@implementation ECTabBar

#pragma mark - Properties

@synthesize tabButtonSize, buttonsInsets;
@synthesize delegate, longPressGestureRecognizer;
@synthesize selectedTabIndex;

- (void)setDelegate:(id<ECTabBarDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateFlags.hasWillAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:willAddTabButton:atIndex:)];
    delegateFlags.hasDidAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:didAddTabButtonAtIndex:)];
    delegateFlags.hasWillRemoveTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:willRemoveTabButtonAtIndex:)];
    delegateFlags.hasDidRemoveTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:didRemoveTabButtonAtIndex:)];
    delegateFlags.hasWillSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:willSelectTabAtIndex:)];
    delegateFlags.hasDidSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:didSelectTabAtIndex:)];
    delegateFlags.hasWillMoveTabFromIndexToIndex = [delegate respondsToSelector:@selector(tabBar:willMoveTabFromIndex:toIndex:)];
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
    // TODO make a content inset instead?
    CGPoint defaultOrigin = CGPointMake(7, 0);
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
    self->selectedTabIndex = NSNotFound;
    self->tabButtonSize = CGSizeMake(300, 0);
    self->buttonsInsets = UIEdgeInsetsMake(7, 0, 7, 7);
    self->additionalControlsDefaultSize = CGSizeMake(41, 0);
}

static void init(ECTabBar *self)
{
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
    CGRect buttonFrame = (CGRect) { CGPointMake(7, 0), tabButtonSize };
    if (buttonFrame.size.height == 0)
        buttonFrame.size.height = bounds.size.height;
    
    // Layout tab button
    for (UIButton *button in tabButtons)
    {
        button.frame = UIEdgeInsetsInsetRect(buttonFrame, buttonsInsets);
        buttonFrame.origin.x += buttonFrame.size.width;
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

- (void)setSelectedTabIndex:(NSUInteger)index
{
    if (selectedTabIndex == index || index >= [tabButtons count])
        return;
    
    if (selectedTabIndex != NSNotFound)
        [[tabButtons objectAtIndex:selectedTabIndex] setSelected:NO];
    
    selectedTabIndex = index;
    
    UIButton *selectedTab = [tabButtons objectAtIndex:selectedTabIndex];
    [selectedTab setSelected:YES];
    
    // Scroll to fully show tab
    CGRect selectedTabFrame = selectedTab.frame;
    selectedTabFrame.origin.x -= buttonsInsets.left + 7;
    selectedTabFrame.size.width += buttonsInsets.left + buttonsInsets.right + 7;
    if (additionalButtonsContainerView)
        selectedTabFrame.size.width += additionalButtonsContainerView.frame.size.width;
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
    CGFloat fixedContentSize = 7;
    if (additionalButtonsContainerView)
        fixedContentSize += additionalButtonsContainerView.frame.size.width;
    self.contentSize = CGSizeMake(tabButtonSize.width * (newTabButtonIndex + 1) + fixedContentSize, self.frame.size.height);
    
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
    
    selectedTabIndex = NSNotFound;
    
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
            break;
        }
            
        default:
            break;
    }
}

@end
