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
    
    struct {
        unsigned int hasWillAddTabButtonAtIndex : 1;
        unsigned int hasDidAddTabButtonAtIndex : 1;
        unsigned int hasWillSelectTabAtIndex :1;
        unsigned int hasDidSelectTabAtIndex : 1;
        unsigned int hasWillMoveTabFromIndexToIndex : 1;
    } delegateFlags;
}

- (void)buttonAddTabAction:(id)sender;
- (void)tabButtonAction:(id)sender;

@end

@implementation ECTabBar

#pragma mark - Properties

@synthesize tabButtonSize, tabButtonInsets;
@synthesize delegate;
@synthesize selectedTabIndex;

- (void)setDelegate:(id<ECTabBarDelegate>)aDelegate
{
    delegate = aDelegate;
    
    delegateFlags.hasWillAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:willAddTabButton:atIndex:)];
    delegateFlags.hasDidAddTabButtonAtIndex = [delegate respondsToSelector:@selector(tabBar:didAddTabButtonAtIndex:)];
    delegateFlags.hasWillSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:willSelectTabAtIndex:)];
    delegateFlags.hasDidSelectTabAtIndex = [delegate respondsToSelector:@selector(tabBar:didSelectTabAtIndex:)];
    delegateFlags.hasWillMoveTabFromIndexToIndex = [delegate respondsToSelector:@selector(tabBar:willMoveTabFromIndex:toIndex:)];
}

@synthesize buttonAddTab;

- (void)setButtonAddTab:(ECButton *)button
{
    [buttonAddTab removeFromSuperview];
    buttonAddTab = button;
    [buttonAddTab addTarget:self action:@selector(buttonAddTabAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:buttonAddTab];
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
    self->tabButtonInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

static void init(ECTabBar *self)
{
    if (self->buttonAddTab == nil)
    {
        self.buttonAddTab = [ECButton new];
        self->buttonAddTab.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self->buttonAddTab setTitle:@"Add" forState:UIControlStateNormal];
    }
    
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
    for (ECButton *button in tabButtons)
    {
        button.frame = UIEdgeInsetsInsetRect(buttonFrame, tabButtonInsets);
        buttonFrame.origin.x += buttonFrame.size.width;
    }
    
    // Show fading layers
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
    
    CGFloat maxBounds = CGRectGetMaxX(bounds);
    if (maxBounds < self.contentSize.width)
    {
        [self.layer addSublayer:rightFadeLayer];
        rightFadeLayer.position = CGPointMake(CGRectGetMaxX(bounds) - rightFadeLayer.bounds.size.width, bounds.origin.y);
        rightFadeLayer.opacity = 1;
    }
    else
    {
        rightFadeLayer.opacity = 0;
        [rightFadeLayer removeFromSuperlayer];
    }
}

#pragma mark - Creation of New Tabs

- (void)addTabButtonWithTitle:(NSString *)title animated:(BOOL)animated
{
    if (!tabButtons)
        tabButtons = [NSMutableArray new];
    
    // TODO use a +tabButtonClass
    NSUInteger newTabButtonIndex = [tabButtons count];
    ECButton *newTabButton = [ECButton new];
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

#pragma mark -

- (void)buttonAddTabAction:(id)sender
{
    [self addTabButtonWithTitle:@"New Tab" animated:YES];
}

#pragma mark - Managing Tabs

- (void)setSelectedTabIndex:(NSUInteger)index
{
    if (selectedTabIndex == index || index >= [tabButtons count])
        return;
    
    if (selectedTabIndex != NSNotFound)
        [[tabButtons objectAtIndex:selectedTabIndex] setSelected:NO];
    
    selectedTabIndex = index;
    
    [[tabButtons objectAtIndex:selectedTabIndex] setSelected:YES];
    
    // TODO scroll to completely visible
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


@end
