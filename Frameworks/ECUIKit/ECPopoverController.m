//
//  ECPopoverController.m
//  MokupControls
//
//  Created by Nicola Peduzzi on 29/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ECPopoverController.h"
#import "ECPopoverView.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#pragma mark -
#pragma makr Custom Gesture Recognizer

@interface InstantGestureRecognizer : UIGestureRecognizer
@end

@implementation InstantGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
    if ((self = [super initWithTarget:target action:action])) 
    {
        self.cancelsTouchesInView = NO;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateRecognized;
}

- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    return NO;
}

@end


#pragma mark -
#pragma makr Popover Controller

#define ANIMATION_DURATION 0.15

@interface ECPopoverController () {
@private
    ECPopoverView *popoverView;
    CGFloat keyboardHeight;
    
    InstantGestureRecognizer *dismissRecognizer;
}

- (void)presentPopoverInView:(UIView *)view WithFrame:(CGRect)frame animated:(BOOL)animated;

- (void)dismissHandler:(UIGestureRecognizer *)recognizer;

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
        
        dismissRecognizer = [[InstantGestureRecognizer alloc] initWithTarget:self action:@selector(dismissHandler:)];
        dismissRecognizer.enabled = NO;
        
        [self setContentViewController:viewController animated:NO];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [popoverView release];
    [dismissRecognizer release];
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
        [self setPopoverContentSize:contentViewController.view.bounds.size animated:NO]; 
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
    // Inset to give a little margin
    allowedRect = CGRectInset(allowedRect, 5, 5);
    // Transform to view's space
    allowedRect = [view convertRect:allowedRect fromView:view.window];
    
    // Point where the arrow should point
    CGPoint arrowPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
    
    CGRect backupFrame = CGRectNull;
    CGRect resultFrame = CGRectZero;
        
    if (arrowDirections | UIPopoverArrowDirectionUp) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.y = CGRectGetMaxY(rect) + popoverView.arrowMargin;
        popoverView.arrowDirection = UIPopoverArrowDirectionUp;
        popoverView.arrowPosition = arrowPoint.x - resultFrame.origin.x;
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

    if (arrowDirections | UIPopoverArrowDirectionDown) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = MAX(allowedRect.origin.x, arrowPoint.x - resultFrame.size.width / 2);
        resultFrame.origin.y = rect.origin.y - resultFrame.size.height - popoverView.arrowSize;
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
    
    if (arrowDirections | UIPopoverArrowDirectionRight) 
    {
        resultFrame = popoverView.bounds;
        resultFrame.origin.x = rect.origin.x - resultFrame.size.width - popoverView.arrowSize;
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
    if (animated) 
    {
        popoverView.layer.shouldRasterize = YES;
        [UIView animateWithDuration:ANIMATION_DURATION animations:^(void) {
            popoverView.alpha = 0;
        } completion:^(BOOL finished) {
            popoverView.layer.shouldRasterize = NO;
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
    [view addSubview:popoverView];
    popoverView.layer.shouldRasterize = YES;
    popoverView.alpha = 0;
    popoverView.frame = frame;
    if (animated)
    {
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
    
    [view.window addGestureRecognizer:dismissRecognizer];
    dismissRecognizer.enabled = YES;
}

- (void)dismissHandler:(UIGestureRecognizer *)recognizer
{
    CGPoint pointInView = [recognizer locationInView:contentViewController.view];
    if ([contentViewController.view pointInside:pointInView withEvent:nil])
        return;
    
    for (UIView *view in passthroughViews) 
    {
        pointInView = [recognizer locationInView:view];
        if ([view pointInside:pointInView withEvent:nil]) 
            return;
    }
    
    [self dismissPopoverAnimated:YES];
    
    [recognizer.view removeGestureRecognizer:dismissRecognizer];
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
