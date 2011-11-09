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
#import "ECShapePopoverView.h"
#import "ECTexturedPopoverView.h"

#pragma mark -
#pragma makr Popover Controller

#define ANIMATION_DURATION 0.15

@interface ECPopoverController () {
@private
    CGRect _keyboardFrame;
    
    ECInstantGestureRecognizer *dismissRecognizer;
    
    BOOL delegateHasPopoverControllerShouldDismissPopover;
    BOOL delegateHasPopoverControllerDidDismissPopover;
}

- (void)_presentPopoverInView:(UIView *)view withFrame:(CGRect)frame animated:(BOOL)animated;

- (void)dismissHandler:(UIGestureRecognizer *)recognizer;

- (void)keyboardShown:(NSNotification*)aNotification;
- (void)keyboardHidden:(NSNotification*)aNotification;

@end


@implementation ECPopoverController

@synthesize popoverView;
@synthesize automaticDismiss, allowedBoundsInsets;

- (ECBasePopoverView *)popoverView
{
    if (!popoverView)
    {
        popoverView = [[[self class] popoverViewClass] new];
    }
    return popoverView;
}

+ (Class)popoverViewClass
{
    return [ECShapePopoverView class];
}

#pragma mark -
#pragma mark Initializing the Popover

static void init(ECPopoverController *self)
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardDidShowNotification object:nil];
    [nc addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardDidHideNotification object:nil];
    
    self->automaticDismiss = YES;
    self.allowedBoundsInsets = UIEdgeInsetsMake(5, 5, 5, 5);
}

- (id)init
{
    if ((self = [super init]))
    {
        init(self);
    }
    return self;
}

- (id)initWithContentViewController:(UIViewController *)viewController
{
    if ((self = [super init])) 
    {
        init(self);
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
    
    // TODO Add navigation bar if needed
    
    // Show content view
    if (animated) 
    {
        // TODO change with opacity animation
        [UIView transitionFromView:self.popoverView.contentView toView:contentViewController.view duration:ANIMATION_DURATION options:0 completion:^(BOOL finished) {
           [self setPopoverContentSize:contentViewController.contentSizeForViewInPopover animated:YES]; 
        }];
    }
    else
    {
        [self setPopoverContentSize:contentViewController.contentSizeForViewInPopover animated:NO]; 
        self.popoverView.contentView = contentViewController.view;
    }
}

- (CGSize)popoverContentSize
{
    return self.popoverView.contentSize;
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
            self.popoverView.contentSize = size;
        }];
    }
    else
    {
        self.popoverView.contentSize = size;
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
    return self.popoverView.arrowDirection;
}

#pragma mark -
#pragma mark Presenting and Dismissing the Popover

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    CGRect allowedRect = [view convertRect:view.window.frame fromView:nil];
    // Remove keyboard
    if (!CGRectIsEmpty(_keyboardFrame))
        allowedRect.size.height -= [view convertRect:_keyboardFrame fromView:nil].size.height;
    // Inset to give a little margin
    allowedRect = UIEdgeInsetsInsetRect(allowedRect, self.allowedBoundsInsets);
    
    // Point where the arrow should point
    CGPoint arrowPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    CGFloat arrowHeight = [self.popoverView arrowSizeForMetaPosition:ECPopoverViewArrowMetaPositionMiddle].height;
    
    CGRect backupFrame = CGRectNull;
    CGRect resultFrame = CGRectZero;
    
    if (arrowDirections & UIPopoverArrowDirectionDown) 
    {
        resultFrame = self.popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, MIN(CGRectGetMaxX(allowedRect) - resultFrame.size.width, arrowPoint.x - resultFrame.size.width / 2));
        resultFrame.origin.y = rect.origin.y - resultFrame.size.height - arrowHeight + self.popoverView.positioningInsets.bottom;
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionDown;
            self.popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
            [self _presentPopoverInView:view withFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionDown;
            self.popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionLeft) 
    {
        resultFrame = self.popoverView.bounds;
        resultFrame.origin.x = CGRectGetMaxX(rect) + arrowHeight - self.popoverView.positioningInsets.left;
        resultFrame.origin.y = MAX(allowedRect.origin.y ,MIN(CGRectGetMaxY(allowedRect) - resultFrame.size.height, arrowPoint.y - resultFrame.size.height / 2));
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionLeft;
            self.popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            [self _presentPopoverInView:view withFrame:resultFrame animated:animated];
            return;
        }
        // TODO instead of check for null, check if intersection of this result frame > intersection with current backupframe
        else if (CGRectIsNull(backupFrame))
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionLeft;
            self.popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionUp) 
    {
        resultFrame = self.popoverView.bounds;
        CGFloat minOrigin = MIN(CGRectGetMaxX(allowedRect) - resultFrame.size.width, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.x = MAX(allowedRect.origin.x, minOrigin);
        resultFrame.origin.y = CGRectGetMaxY(rect) + arrowHeight - self.popoverView.positioningInsets.top;
        self.popoverView.arrowDirection = UIPopoverArrowDirectionUp;
        self.popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            [self _presentPopoverInView:view withFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections & UIPopoverArrowDirectionRight) 
    {
        resultFrame = self.popoverView.bounds;
        resultFrame.origin.x = rect.origin.x - resultFrame.size.width - arrowHeight + self.popoverView.positioningInsets.right;
        resultFrame.origin.y = MIN(CGRectGetMaxY(allowedRect) - resultFrame.size.height, arrowPoint.y - resultFrame.size.height / 2);
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionRight;
            self.popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            [self _presentPopoverInView:view withFrame:resultFrame animated:animated];
            return;
        }
        else if (CGRectIsNull(backupFrame))
        {
            self.popoverView.arrowDirection = UIPopoverArrowDirectionRight;
            self.popoverView.arrowPosition = arrowPoint.y - resultFrame.origin.y;
            backupFrame = resultFrame;
        }
    }
    
    [self _presentPopoverInView:view withFrame:backupFrame animated:animated];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    UIView *itemView = item.customView != nil ? item.customView : [item performSelector:@selector(view)];
    [self presentPopoverFromRect:[itemView frame] inView:[itemView superview] permittedArrowDirections:arrowDirections animated:animated];
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (delegateHasPopoverControllerShouldDismissPopover && ![delegate popoverControllerShouldDismissPopover:(UIPopoverController *)self])
        return;
    
    if (animated) 
    {
        self.popoverView.layer.shouldRasterize = YES;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            self.popoverView.alpha = 0;
        } completion:^(BOOL finished) {
            self.popoverView.layer.shouldRasterize = NO;
            [self.popoverView removeFromSuperview];
            popoverVisible = NO;
            
            if (delegateHasPopoverControllerDidDismissPopover)
                [delegate popoverControllerDidDismissPopover:(UIPopoverController *)self];
        }];
    }
    else
    {
        [self.popoverView removeFromSuperview];
        popoverVisible = NO;
        
        if (delegateHasPopoverControllerDidDismissPopover)
            [delegate popoverControllerDidDismissPopover:(UIPopoverController *)self];
    }
}

#pragma mark -
#pragma mark Private Methods

- (void)_presentPopoverInView:(UIView *)view withFrame:(CGRect)frame animated:(BOOL)animated
{
    [view addSubview:self.popoverView];
    frame.origin.x = roundf(frame.origin.x);
    frame.origin.y = roundf(frame.origin.y);
    self.popoverView.frame = frame;
    if (animated)
    {
        self.popoverView.layer.shouldRasterize = YES;
        self.popoverView.alpha = 0;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            self.popoverView.alpha = 1;
        } completion:^(BOOL finished) {
            self.popoverView.layer.shouldRasterize = NO;
        }];
    }
    else
    {
        self.popoverView.alpha = 1;
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
    CGPoint pointInView = [recognizer locationInView:self.popoverView];
    if ([self.popoverView pointInside:pointInView withEvent:nil])
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
    _keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
}

- (void)keyboardHidden:(NSNotification *)aNotification
{
    _keyboardFrame = CGRectZero;
}

@end


@implementation ECTexturedPopoverController

+ (Class)popoverViewClass
{
    return [ECTexturedPopoverView class];
}

@end
