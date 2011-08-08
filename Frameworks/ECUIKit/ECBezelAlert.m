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
    UIViewAutoresizing autoresizingMask;
}

#pragma mark - Properties

@synthesize presentingViewController, bezelCornerRadius, visibleTimeInterval, margins, presentationAnimationType;

- (void)setMargins:(UIEdgeInsets)m
{
    margins = m;
    
    autoresizingMask = 0;
    if (margins.top < 0) autoresizingMask |= UIViewAutoresizingFlexibleTopMargin;
    if (margins.right < 0) autoresizingMask |= UIViewAutoresizingFlexibleRightMargin;
    if (margins.bottom < 0) autoresizingMask |= UIViewAutoresizingFlexibleBottomMargin;
    if (margins.left < 0) autoresizingMask |= UIViewAutoresizingFlexibleLeftMargin;
    
    if (self.isViewLoaded)
        self.view.autoresizingMask = autoresizingMask;
}

#pragma mark - Controller Methods

+ (ECBezelAlert *)centerBezelAlert
{
    static ECBezelAlert *_centerBezelAlert = nil;
    if (_centerBezelAlert == nil)
    {
        _centerBezelAlert = [ECBezelAlert new];
        _centerBezelAlert.presentationAnimationType = ECBezelAlertAnimationFade | ECBezelAlertAnimationPop;
    }
    return _centerBezelAlert;
}

+ (ECBezelAlert *)bottomBezelAlert
{
    static ECBezelAlert *_bottomBezelAlert = nil;
    if (_bottomBezelAlert == nil)
    {
        _bottomBezelAlert = [ECBezelAlert new];
        _bottomBezelAlert.margins = UIEdgeInsetsMake(-1, -1, 20, -1);
    }
    return _bottomBezelAlert;
}

- (id)init
{
    if ((self = [super init]))
    {
        bezelCornerRadius = 10;
        self.margins = UIEdgeInsetsMake(-1, -1, -1, -1);
        presentationAnimationType = ECBezelAlertAnimationFade;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)loadView
{
    // View background image
    UIImage *bezelBackgroundImage = [[UIImage imageWithSize:CGSizeMake(bezelCornerRadius * 2 + 2, bezelCornerRadius * 2 + 2) block:^(CGContextRef ctx, CGRect rect) {
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithWhite:0 alpha:0.5].CGColor);
        CGContextAddPath(ctx, [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:bezelCornerRadius].CGPath);
        CGContextFillPath(ctx);
    }] resizableImageWithCapInsets:UIEdgeInsetsMake(bezelCornerRadius, bezelCornerRadius, bezelCornerRadius, bezelCornerRadius)];
    
    // Create view
    UIImageView *bezelView = [[UIImageView alloc] initWithImage:bezelBackgroundImage];
//    bezelView.contentMode = UIViewContentModeScaleToFill;
#warning TODO the resulting immage is not properly scaled (corners are deformed)
    bezelView.autoresizingMask = autoresizingMask;
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
    
    // Calculate bezel frame
    CGRect bezelFrame = CGRectInset(contentFrame, -bezelCornerRadius, -bezelCornerRadius);
    // Horizontal positioning
    if (margins.left >= 0)
        bezelFrame.origin.x = margins.left;
    else if (margins.right >= 0)
        bezelFrame.origin.x = presentingBounds.size.width - bezelFrame.size.width - margins.right;
    else
        bezelFrame.origin.x = (presentingBounds.size.width - bezelFrame.size.width) / 2.;
    // Vertical positioning
    if (margins.top >= 0)
        bezelFrame.origin.y = margins.top;
    else if (margins.bottom >= 0)
        bezelFrame.origin.y = presentingBounds.size.height - bezelFrame.size.height - margins.bottom;
    else
        bezelFrame.origin.y = (presentingBounds.size.height - bezelFrame.size.height) / 2.;
    
    // Animate bezel view
    if (self.view.superview)
    {
        // If already visible, change content with cross fade
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
        viewController.view.alpha = 1;
        viewController.view.frame = contentFrame;
        
        if (presentationAnimationType)
        {
            if (presentationAnimationType & ECBezelAlertAnimationFade)
                self.view.alpha = 0;
            
            if (presentationAnimationType & ECBezelAlertAnimationPop)
                self.view.transform = CGAffineTransformMakeScale(0.01, 0.01);    
            
            [UIView animateWithDuration:0.10 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
                self.view.alpha = 1;
                if (presentationAnimationType & ECBezelAlertAnimationPop)
                    self.view.transform = CGAffineTransformMakeScale(1.4, 1.4);
            } completion:^(BOOL finished) {
                if (presentationAnimationType & ECBezelAlertAnimationPop)
                {
                    [UIView animateWithDuration:0.05 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^(void) {
                        self.view.transform = CGAffineTransformIdentity;
                    } completion:nil];
                }
            }];
        }        
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
            [self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            [self.childViewControllers makeObjectsPerformSelector:@selector(removeFromParentViewController)];
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
    
    CGRect imageViewFrame = CGRectNull;
    if (imageView)
    {
        imageView.center = CGPointMake(viewFrame.size.width / 2, imageView.bounds.size.height / 2);
        imageViewFrame = imageView.frame;
    }
    
    CGRect labelFrame = CGRectNull;
    if (label)
    {
        label.center = CGPointMake(viewFrame.size.width / 2, imageViewFrame.size.height + label.bounds.size.height / 2);
        labelFrame = label.frame;
    }
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectUnion(imageViewFrame, labelFrame)];
    [view addSubview:imageView];
    [view addSubview:label];
    
    UIViewController *viewController = [UIViewController new];
    viewController.view = view;
    viewController.contentSizeForViewInPopover = viewFrame.size;
    
    [self addAlertMessageWithViewController:viewController displayImmediatly:immediate];
}

@end
