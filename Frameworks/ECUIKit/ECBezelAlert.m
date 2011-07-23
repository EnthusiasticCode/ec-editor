//
//  ECBezelAlert.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 23/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECBezelAlert.h"
#import <QuartzCore/QuartzCore.h>

#import "UIImage+BlockDrawing.h"

@implementation ECBezelAlert {
    NSTimer *alertTimer;
}

@synthesize presentingViewController, bezelCornerRadius, visibleTimeInterval;

#pragma mark - Controller Methods

+ (ECBezelAlert *)sharedAlert
{
    static ECBezelAlert *sharedAlert = nil;
    if (sharedAlert == nil)
        sharedAlert = [ECBezelAlert new];
    return sharedAlert;
}

- (id)init {
    self = [super init];
    if (self) {
        bezelCornerRadius = 10;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)loadView
{
    // View background image
    UIImage *bezelBackgroundImage = [[UIImage imageWithSize:CGSizeMake(bezelCornerRadius * 2 + 1, bezelCornerRadius * 2 + 1) block:^(CGContextRef ctx, CGRect rect) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
        CGContextAddPath(ctx, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:bezelCornerRadius].CGPath);
        CGContextFillPath(ctx);
    }] resizableImageWithCapInsets:UIEdgeInsetsMake(bezelCornerRadius, bezelCornerRadius, bezelCornerRadius, bezelCornerRadius)];
    
    // Create view
    UIImageView *bezelView = [[UIImageView alloc] initWithImage:bezelBackgroundImage];
    bezelView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.view = bezelView;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

#pragma mark - Internal Allerting Methods

- (void)presentFirstChildViewController
{
    ECASSERT([self.childViewControllers count] != 0);
    
    UIViewController *viewController = [self.childViewControllers objectAtIndex:0];
    
    // Layout content view
    CGRect contentFrame = (CGRect){ CGPointMake(bezelCornerRadius, bezelCornerRadius), viewController.contentSizeForViewInPopover };
    // TODO check if size == Zero and use view size instead
    ECASSERT(!CGSizeEqualToSize(contentFrame.size, CGSizeZero));
    viewController.view.frame = contentFrame;
    [self.view addSubview:viewController.view];
    
    // Get presenting view bounds
    if (presentingViewController == nil)
    {
        ECASSERT([[UIApplication sharedApplication].windows count]);
        presentingViewController = [[[UIApplication sharedApplication].windows objectAtIndex:0] rootViewController];
    }
    CGRect presentingBounds = presentingViewController.view.bounds;
    // TODO intersect with keyboard frame
    
    // Layout bezel view
    CGRect bezelFrame = CGRectInset(contentFrame, -bezelCornerRadius, -bezelCornerRadius);
    bezelFrame = (CGRect){ CGPointMake((presentingBounds.size.width - bezelFrame.size.width) / 2, presentingBounds.size.height - bezelFrame.size.height - 20), bezelFrame.size };
    if (self.view.superview)
    {
        viewController.view.alpha = 0;
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            viewController.view.alpha = 1;
            self.view.frame = bezelFrame;
            viewController.view.frame = contentFrame;
        } completion:nil];
    }
    else
    {
        self.view.frame = bezelFrame;
        self.view.alpha = 0;
        viewController.view.alpha = 1;
        viewController.view.frame = contentFrame;
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            self.view.alpha = 1;
        } completion:nil];
    }
    
    // Present view
    [presentingViewController.view addSubview:self.view];
}

- (void)alertTimerExpires:(NSTimer *)timer
{
    UIViewController *viewController = [self.childViewControllers objectAtIndex:0];
    if ([self.childViewControllers count] > 1)
    {
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            viewController.view.alpha = 0;
        } completion:^(BOOL finished) {
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
            [self presentFirstChildViewController];
        }];
    }
    else
    {
        [alertTimer invalidate];
        alertTimer = nil;
        [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
            [self.view removeFromSuperview];
        }];
    }
}

#pragma mark - Allerting Methods

- (void)addAlertMessageWithViewController:(UIViewController *)viewController displayImmediatly:(BOOL)immediate
{
    // Reset the fade out timer if readding the same controller
    if ([self.childViewControllers count] && [self.childViewControllers objectAtIndex:0] == viewController)
    {
        [alertTimer invalidate];
        alertTimer = nil;
    }
    else 
    {
        // Remove all queued controllers if immediate display
        if (immediate)
        {
            for (UIView *view in self.view.subviews)
            {
                [view removeFromSuperview];
            }
            for (UIViewController *controller in self.childViewControllers)
            {
                [controller removeFromParentViewController];
            }
        }
        
        [self addChildViewController:viewController];
    }
    
    if (immediate || [self.childViewControllers count] == 1)
    {
        [self presentFirstChildViewController];
    }
    
    if (visibleTimeInterval == 0)
        visibleTimeInterval = 1;
    
    // Schedule the fadeing timer
    if (alertTimer == nil)
        alertTimer = [NSTimer scheduledTimerWithTimeInterval:visibleTimeInterval 
                                                      target:self 
                                                    selector:@selector(alertTimerExpires:) 
                                                    userInfo:nil 
                                                     repeats:YES];
}

- (void)addAlertMessageWithText:(NSString *)text image:(UIImage *)image displayImmediatly:(BOOL)immediate
{
    if (text == nil && image == nil)
        return;
    
    CGRect viewFrame = CGRectNull;
    
    UIImageView *imageView = nil;
    if (image)
    {
        imageView = [[UIImageView alloc] initWithImage:image];
        viewFrame = CGRectUnion(viewFrame, imageView.frame);
    }
    
    UILabel *label = nil;
    if (text)
    {
        label = [UILabel new];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.textAlignment = UITextAlignmentCenter;
        label.text = text;
        [label sizeToFit];
        viewFrame = CGRectUnion(viewFrame, label.frame);
    }
    
    if (imageView)
        imageView.center = CGPointMake(viewFrame.size.width / 2, imageView.bounds.size.height / 2);
    if (label)
        label.center = CGPointMake(viewFrame.size.width / 2, imageView.bounds.size.height + label.bounds.size.height / 2);
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectUnion(imageView.frame, label.frame)];
    [view addSubview:imageView];
    [view addSubview:label];
    
    UIViewController *viewController = [UIViewController new];
    viewController.view = view;
    viewController.contentSizeForViewInPopover = viewFrame.size;
    
    [self addAlertMessageWithViewController:viewController displayImmediatly:immediate];
}

@end
