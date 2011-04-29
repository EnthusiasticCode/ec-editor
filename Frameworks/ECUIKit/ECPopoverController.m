//
//  ECPopoverController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECPopoverController.h"
#import "ECPopoverView.h"

#define ANIMATION_DURATION 0.15

@interface ECPopoverController () {
@private
    ECPopoverView *popoverView;
    CGFloat keyboardHeight;
    
    UITapGestureRecognizer *dismissRecognizer;
}

- (void)presentPopoverInView:(UIView *)view WithFrame:(CGRect)frame animated:(BOOL)animated;

- (void)dismissHandler:(UITapGestureRecognizer *)recognizer;

- (void)keyboardShown:(NSNotification*)aNotification;
- (void)keyboardHidden:(NSNotification*)aNotification;

@end


@implementation ECPopoverController

#pragma mark -
#pragma mark Initializing the Popover

static void init(ECPopoverController *self)
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHidden:) name:UIKeyboardDidHideNotification object:nil];
}

- (id)initWithContentViewController:(UIViewController *)viewController
{
    if ((self = [super init])) 
    {
        popoverView = [ECPopoverView new];
        
        dismissRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHandler:)];
        dismissRecognizer.numberOfTapsRequired = 1;
        dismissRecognizer.cancelsTouchesInView = NO;
        dismissRecognizer.enabled = NO;
        
        [self setContentViewController:viewController animated:NO];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [popoverView release];
    [super dealloc];
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
    contentViewController = viewController;
    if (animated) 
    {
        // TODO change with opacity animation
        [UIView transitionFromView:popoverView.contentView toView:contentViewController.view duration:ANIMATION_DURATION options:0 completion:^(BOOL finished) {
           [self setPopoverContentSize:contentViewController.view.bounds.size animated:YES]; 
        }];
    }
    else
    {
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
    CGRect allowedRect = view.window.bounds;
    // Removing status bar anyway
    allowedRect.origin.y += 20;
    allowedRect.size.height -= 20;
    // Remove keyboard
    allowedRect.size.height -= keyboardHeight;
    // Transform to view's space
    allowedRect = [view convertRect:allowedRect fromView:view.window];
    
    // Point where the arrow should point
    CGPoint arrowPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGRect backupFrame = CGRectNull;
    CGRect resultFrame;
        
    if (arrowDirections | UIPopoverArrowDirectionUp) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.y = CGRectGetMaxY(rect) + popoverView.arrowSize;
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        else
        {
            backupFrame = resultFrame;
        }
    }
    
    if (arrowDirections | UIPopoverArrowDirectionLeft) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = CGRectGetMaxX(rect) + popoverView.arrowSize;
        resultFrame.origin.y = MAX(allowedRect.origin.y, arrowPoint.y - resultFrame.size.height / 2);
        if (CGRectContainsRect(allowedRect, resultFrame)) 
        {
            [self presentPopoverInView:view WithFrame:resultFrame animated:animated];
            return;
        }
        // TODO instead of check for null, check if intersection of this result frame > intersection with current backupframe
        else if (CGRectIsNull(backupFrame))
        {
            backupFrame = resultFrame;
        }
    }

    if (arrowDirections | UIPopoverArrowDirectionDown) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.y = rect.origin.y - resultFrame.size.height - popoverView.arrowSize;
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
    
    if (arrowDirections | UIPopoverArrowDirectionRight) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = rect.origin.x - resultFrame.size.width - popoverView.arrowSize;
        resultFrame.origin.y = MAX(allowedRect.origin.y, arrowPoint.y - resultFrame.size.height / 2);
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
    
    [self presentPopoverInView:view WithFrame:backupFrame animated:animated];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated
{
    // TODO implement this
    abort();
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
    if (animated) 
    {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.alpha = 0;
        } completion:^(BOOL finished) {
            [popoverView removeFromSuperview];
        }];
    }
    else
    {
        [popoverView removeFromSuperview];
    }
    popoverVisible = NO;
}

#pragma mark -
#pragma mark Private Methods

- (void)presentPopoverInView:(UIView *)view WithFrame:(CGRect)frame animated:(BOOL)animated
{
    popoverView.alpha = 0;
    popoverView.frame = frame;
    [view addSubview:popoverView];
    if (animated)
    {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.alpha = 1;
        }];
    }
    else
    {
        popoverView.alpha = 1;
    }
    popoverVisible = YES;
    
    [view.window addGestureRecognizer:dismissRecognizer];
    dismissRecognizer.enabled = YES;
}

- (void)dismissHandler:(UITapGestureRecognizer *)recognizer
{
    UIView *recognizerView = recognizer.view;
    CGPoint pointOfView = [recognizer locationInView:recognizerView];
    UIView *hitView = [recognizerView hitTest:pointOfView withEvent:nil];
    
    while (hitView && hitView != recognizerView) 
    {
        if ([passthroughViews containsObject:hitView]) 
            return;
        hitView = hitView.superview;
    }
    
    [self dismissPopoverAnimated:YES];
    
    [recognizerView removeGestureRecognizer:dismissRecognizer];
    dismissRecognizer.enabled = NO;
}

- (void)keyboardShown:(NSNotification *)aNotification
{
    keyboardHeight = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
}

- (void)keyboardHidden:(NSNotification *)aNotification
{
    keyboardHeight = 0;
}

@end
