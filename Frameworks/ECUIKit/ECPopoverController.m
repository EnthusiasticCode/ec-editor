//
//  ECPopoverController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ECPopoverController.h"
#import "ECInstantGestureRecognizer.h"

#pragma mark -
#pragma makr Popover Controller

#define ANIMATION_DURATION 0.15

@interface ECPopoverController () {
@private
    CGFloat keyboardHeight;
    
    ECInstantGestureRecognizer *dismissRecognizer;
    
    BOOL delegateHasPopoverControllerShouldDismissPopover;
    BOOL delegateHasPopoverControllerDidDismissPopover;
}

- (void)presentPopoverInView:(UIView *)view WithFrame:(CGRect)frame animated:(BOOL)animated;

- (void)dismissHandler:(UIGestureRecognizer *)recognizer;

- (void)keyboardShown:(NSNotification*)aNotification;
- (void)keyboardHidden:(NSNotification*)aNotification;

@end


@implementation ECPopoverController

@synthesize popoverView;
@synthesize automaticDismiss;

#pragma mark -
#pragma mark Initializing the Popover

static void preinit(ECPopoverController *self)
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardDidHideNotification object:nil];
    
    self->automaticDismiss = YES;
}

- (id)init
{
    preinit(self);
    if ((self = [super init]))
    {
        popoverView = [ECPopoverView new];
    }
    return self;
}

- (id)initWithContentViewController:(UIViewController *)viewController
{
    preinit(self);
    if ((self = [super init])) 
    {
        popoverView = [ECPopoverView new];
        [self setContentViewController:viewController animated:NO];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark -
#pragma mark Configuring the Popover Attributes

@synthesize contentViewController;

- (void)setContentViewController:(UIViewController *)viewController
{
    [self setContentViewController:viewController animated:NO];
}

- (void)setContentViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (contentViewController == viewController)
        return;
    
    contentViewController = viewController;
    
    // Add navigation bar if needed
    if ([contentViewController isKindOfClass:[UINavigationController class]])
    {
        [(UINavigationController *)contentViewController setNavigationBarHidden:YES];
        
        UIView *navigationBar = [UIView new];
        navigationBar.backgroundColor = [UIColor redColor];
        navigationBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        popoverView.barView = navigationBar;
    }
    else
    {
        popoverView.barView = nil;
    }
    
    // Show content view
    if (animated) 
    {
        // TODO change with opacity animation
        [UIView transitionFromView:popoverView.contentView toView:contentViewController.view duration:ANIMATION_DURATION options:0 completion:^(BOOL finished) {
           [self setPopoverContentSize:contentViewController.contentSizeForViewInPopover animated:YES]; 
        }];
    }
    else
    {
        [self setPopoverContentSize:contentViewController.contentSizeForViewInPopover animated:NO]; 
        popoverView.contentView = contentViewController.view;
    }
}

- (CGSize)popoverContentSize
{
    return popoverView.contentSize;
}

- (void)setPopoverContentSize:(CGSize)size
{
    [self setPopoverContentSize:size animated:NO];
}

- (void)setPopoverContentSize:(CGSize)size animated:(BOOL)animated
{
    if (animated) 
    {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.contentSize = size;
        }];
    }
    else
    {
        popoverView.contentSize = size;
    }
}

@synthesize passthroughViews;
@synthesize delegate;

- (void)setDelegate:(id<UIPopoverControllerDelegate>)aDelegate
{
    delegate = aDelegate;
    delegateHasPopoverControllerShouldDismissPopover = [delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)];
    delegateHasPopoverControllerDidDismissPopover = [delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)];
}

#pragma mark -
#pragma mark Getting the Popover Attributes

@synthesize popoverVisible;

- (UIPopoverArrowDirection)popoverArrowDirection
{
    return popoverView.arrowDirection;
}

#pragma mark -
#pragma mark Presenting and Dismissing the Popover

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    UIView *rootView = view.window.rootViewController.view;
    CGRect allowedRect = rootView.bounds;
    // Remove keyboard
    allowedRect.size.height -= keyboardHeight;
    // Inset to give a little margin
    allowedRect = CGRectInset(allowedRect, 5, 5);
    // Transform to view's space
    UIView *v = view;
    CGPoint viewOriging;
    while (v != rootView)
    {
        viewOriging = v.frame.origin;
        rect.origin.x += viewOriging.x;
        rect.origin.y += viewOriging.y;
        v = v.superview;
    }
    
    // Point where the arrow should point
    CGPoint arrowPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGRect backupFrame = CGRectNull;
    CGRect resultFrame = CGRectZero;
    
    if (arrowDirections & UIPopoverArrowDirectionDown) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, MIN(CGRectGetMaxX(allowedRect) - resultFrame.size.width, arrowPoint.x - resultFrame.size.width / 2));
        resultFrame.origin.y = rect.origin.y - resultFrame.size.height - popoverView.arrowMargin;
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionDown;
            popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionDown;
            popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionLeft) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = CGRectGetMaxX(rect) + popoverView.arrowMargin;
        resultFrame.origin.y = MAX(allowedRect.origin.y ,MIN(CGRectGetMaxY(allowedRect) - resultFrame.size.height, arrowPoint.y - resultFrame.size.height / 2));
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionLeft;
            popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        // TODO instead of check for null, check if intersection of this result frame > intersection with current backupframe
        else if (CGRectIsNull(backupFrame))
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionLeft;
            popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionUp) 
    {
        resultFrame = popoverView.bounds;
        CGFloat minOrigin = MIN(CGRectGetMaxX(allowedRect) - resultFrame.size.width, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.x = MAX(allowedRect.origin.x, minOrigin);
        resultFrame.origin.y = CGRectGetMaxY(rect) + popoverView.arrowMargin;
        popoverView.arrowDirection = UIPopoverArrowDirectionUp;
        popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionRight) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = rect.origin.x - resultFrame.size.width - popoverView.arrowMargin;
        resultFrame.origin.y = MIN(CGRectGetMaxY(allowedRect) - resultFrame.size.height, arrowPoint.y - resultFrame.size.height / 2);
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionRight;
            popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            popoverView.arrowDirection = UIPopoverArrowDirectionRight;
            popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            backupFrame = resultFrame;
        }
    }
    
    [self presentPopoverInView:view WithFrame:backupFrame animated:animated];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    // TODO implement this
    abort();
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (delegateHasPopoverControllerShouldDismissPopover && ![delegate popoverControllerShouldDismissPopover:(UIPopoverController *)self])
        return;
    
    if (animated) 
    {
        popoverView.layer.shouldRasterize = YES;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.alpha = 0;
        } completion:^(BOOL finished) {
            popoverView.layer.shouldRasterize = NO;
            [popoverView removeFromSuperview];
            popoverVisible = NO;
            
            if (delegateHasPopoverControllerDidDismissPopover)
                [delegate popoverControllerDidDismissPopover:(UIPopoverController *)self];
        }];
    }
    else
    {
        [popoverView removeFromSuperview];
        popoverVisible = NO;
        
        if (delegateHasPopoverControllerDidDismissPopover)
            [delegate popoverControllerDidDismissPopover:(UIPopoverController *)self];
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)presentPopoverInView:(UIView *)view WithFrame:(CGRect)frame animated:(BOOL)animated
{
    if (popoverView.superview != nil)
        return;
    
    [view.window.rootViewController.view addSubview:popoverView];
    frame.origin.x = roundf(frame.origin.x);
    frame.origin.y = roundf(frame.origin.y);
    popoverView.frame = frame;
    if (animated)
    {
        popoverView.layer.shouldRasterize = YES;
        popoverView.alpha = 0;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.alpha = 1;
        } completion:^(BOOL finished) {
            popoverView.layer.shouldRasterize = NO;
        }];
    }
    else
    {
        popoverView.alpha = 1;
    }
    popoverVisible = YES;
    
    if (automaticDismiss) 
    {
        if (!dismissRecognizer)
            dismissRecognizer = [[ECInstantGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHandler:)];
        [view.window addGestureRecognizer:dismissRecognizer];
    }
}

- (void)dismissHandler:(UIGestureRecognizer *)recognizer
{
    CGPoint pointInView = [recognizer locationInView:popoverView];
    if ([popoverView pointInside:pointInView withEvent:nil])
        return;
    
    for (UIView *view in passthroughViews) 
    {
        pointInView = [recognizer locationInView:view];
        if ([view pointInside:pointInView withEvent:nil]) 
            return;
    }
    
    [self dismissPopoverAnimated:YES];
    
    [recognizer.view removeGestureRecognizer:dismissRecognizer];
}

- (void)keyboardShown:(NSNotification *)aNotification
{
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    keyboardHeight = abs(keyboardFrame.origin.x) > abs(keyboardFrame.origin.y) ? keyboardFrame.size.width : keyboardFrame.size.height;
}

- (void)keyboardHidden:(NSNotification *)aNotification
{
    keyboardHeight = 0;
}

@end
