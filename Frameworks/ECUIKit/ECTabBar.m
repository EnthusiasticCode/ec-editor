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

#pragma mark - View Lifecicle

static void updateFadeViews(ECTabBar *self)
{    
    // Update left fade layer
    if (!self->leftFadeLayer)
    {
        self->leftFadeLayer = [CAGradientLayer layer];
        [self.layer addSublayer:self->leftFadeLayer];
    }
    self->leftFadeLayer.colors = [NSArray arrayWithObjects:
                                  objc_unretainedObject(self.backgroundColor.CGColor),
                                  objc_unretainedObject([UIColor clearColor].CGColor), nil];
    
    // Update right fade layer
    if (!self->rightFadeLayer)
    {
        self->rightFadeLayer = [CAGradientLayer layer];
        [self.layer addSublayer:self->rightFadeLayer];
    }
    self->rightFadeLayer.colors = [NSArray arrayWithObjects:
                                  objc_unretainedObject([UIColor clearColor].CGColor),
                                   objc_unretainedObject(self.backgroundColor.CGColor), nil];
}

static void preinit(ECTabBar *self)
{
    self->selectedTabIndex = NSNotFound;
    self->tabButtonSize = CGSizeMake(100, 0);
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
}

#pragma mark - Creation of New Tabs

- (void)addTabButtonWithTitle:(NSString *)title animated:(BOOL)animated
{
    if (!tabButtons)
        tabButtons = [NSMutableArray new];
    
    // TODO use a +tabButtonClass
    ECButton *newTabButton = [ECButton new];
    [newTabButton setTitle:title forState:UIControlStateNormal];
    [newTabButton addTarget:self action:@selector(tabButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if (delegateFlags.hasWillAddTabButtonAtIndex 
        && ![delegate tabBar:self willAddTabButton:newTabButton atIndex:[tabButtons count]])
        return;
    
    [tabButtons addObject:newTabButton];
    
    // TODO animate
    [self addSubview:newTabButton];
    
    if (delegateFlags.hasDidAddTabButtonAtIndex)
        [delegate tabBar:self didAddTabButtonAtIndex:[tabButtons count] - 1];
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
