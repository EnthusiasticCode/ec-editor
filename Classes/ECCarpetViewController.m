//
//  ECCarpetViewController.m
//  edit
//
//  Created by Nicola Peduzzi on 18/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCarpetViewController.h"

@interface ECCarpetViewController () 

// Return the unit size of the view controller's at the specified index
// for the given orientation.
- (CGFloat)unitsDimensionForViewControllerAtIndex:(NSInteger)anIndex 
                                  withOrientation:(UIDeviceOrientation)anOrientation;

- (CGRect)frameForMainViewControllerConsideringHidden:(UIViewController*)aController;

- (CGRect)frameForViewController:(UIViewController*)aController;

@end

@implementation ECCarpetViewController

@synthesize delegate;
@synthesize viewControllers;
@synthesize mainViewController;
@synthesize viewControllersSizes;
@synthesize direction;
@synthesize animationDuration;
@synthesize gestureRecognizer;

- (void)setGestureRecognizer:(UIGestureRecognizer *)aRecognizer
{
    if (aRecognizer != gestureRecognizer)
    {
        UIGestureRecognizer *oldRecognizer = gestureRecognizer;
        gestureRecognizer = [aRecognizer retain];
        if([self isViewLoaded])
        {
            [self.view removeGestureRecognizer:oldRecognizer];
            [self.view addGestureRecognizer:gestureRecognizer];
        }
        [oldRecognizer removeTarget:self action:@selector(handleGesture:)];
        [oldRecognizer release];
        [gestureRecognizer addTarget:self action:@selector(handleGesture:)];
    }
}

#pragma mark -
#pragma mark UIViewController overloads implementation

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        animationDuration = 0.3;
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
    UIView * root = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    root.autoresizingMask = UIViewAutoresizingFlexibleWidth
        | UIViewAutoresizingFlexibleHeight
        | UIViewAutoresizingFlexibleTopMargin
        | UIViewAutoresizingFlexibleRightMargin
        | UIViewAutoresizingFlexibleBottomMargin
        | UIViewAutoresizingFlexibleLeftMargin;
    self.view = root;
    
    // Add carpet subviews
    for(UIViewController* controller in [viewControllers objectEnumerator])
    {
        if(controller == mainViewController)
        {
            controller.view.frame = root.bounds;
        }
        else
        {
            // FIX here the device orientation is unknown.
            controller.view.frame = [self frameForViewController:controller];
            controller.view.hidden = YES;
        }
        controller.view.autoresizingMask = root.autoresizingMask;
        [root addSubview:controller.view];
    }
    
    // Add gesture recognition

    [root bringSubviewToFront:mainViewController.view];    
    [root release];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    BOOL result = YES;
    for (id c in [viewControllers objectEnumerator])
    {
        result &= [c shouldAutorotateToInterfaceOrientation:interfaceOrientation];
    }
    // TODO debug
    result = YES;
    return result;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // Animate frames to resize acording to orientation
    [UIView animateWithDuration:duration animations:^(void) {
        for (UIViewController* controller in [viewControllers objectEnumerator])
        {
            if (controller == mainViewController)
                controller.view.frame = [self frameForMainViewControllerConsideringHidden:nil];
            else
                controller.view.frame = [self frameForViewController:controller];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    // TODO release viewControllers views if hidden.
    
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    self.gestureRecognizer = nil;
    [viewControllers release];
    [viewControllersSizes release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom controller messages implementation

- (void)moveCarpetInDirection:(ECCarpetViewControllerMove)aSide 
                     animated:(BOOL)doAnimation
{
    // TODO move with finger movement than snap
    // TODO call delegate's methods
    // Retrieve controllers to reveal/hide
    UIViewController *toShow = nil, *toHide = nil;
    BOOL afterMainController = NO;
    NSEnumerator *viewControllersEnum = (aSide == ECCarpetMoveDownOrRight) 
        ? [viewControllers objectEnumerator] 
        : [viewControllers reverseObjectEnumerator];
    for (UIViewController* controller in viewControllersEnum)
    {
        if (controller == mainViewController)
        {
            afterMainController = YES;
            continue;
        }
        if (!afterMainController)
        {
            if (toShow == nil && controller.view.hidden)
            {
                toShow = controller;
            }
        }
        else if (!controller.view.hidden)
        {
            toHide = controller;
            break;
        }
    }
    // Delegate confirmation
    if ([delegate respondsToSelector:@selector(carpetViewController:willMoveTo:showingViewController:hidingViewController:)]
        && ![delegate carpetViewController:self willMoveTo:aSide showingViewController:toShow hidingViewController:toHide])
    {
        return;
    }
    //
    if (toHide == nil)
    {
        toShow.view.hidden = NO;
    }
    // Animate
    CGRect newFrame = [self frameForMainViewControllerConsideringHidden:toHide];
    if (doAnimation)
    {
        [UIView animateWithDuration:animationDuration animations:^(void) {
            mainViewController.view.frame = newFrame;
        } completion:^(BOOL finished) {
            if (toHide != nil)
            {
                toHide.view.hidden = YES;
            }
            if ([delegate respondsToSelector:@selector(carpetViewController:didMoveTo:showingViewController:hidingViewController:)])
            {
                [delegate carpetViewController:self didMoveTo:aSide showingViewController:toShow hidingViewController:toHide];
            }
        }];
    }
    else
    {
        mainViewController.view.frame = newFrame;
        if (toHide != nil)
        {
            toHide.view.hidden = YES;
        }
        if ([delegate respondsToSelector:@selector(carpetViewController:didMoveTo:showingViewController:hidingViewController:)])
        {
            [delegate carpetViewController:self didMoveTo:aSide showingViewController:toShow hidingViewController:toHide];
        }
    }
}

- (IBAction)moveCarpetDownRight:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveDownOrRight animated:YES];
}

- (IBAction)moveCarpetUpLeft:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveUpOrLeft animated:YES];
}

- (void)handleGesture:(UIGestureRecognizer*)sender
{
    // Pan gestures
    if ([sender isKindOfClass:[UIPanGestureRecognizer class]])
    {
        if (sender.state == UIGestureRecognizerStateEnded)
        {
            // TODO use this point to move main controller's view continuously
            CGPoint trans = [(UIPanGestureRecognizer*)sender translationInView:self.view];
            ECCarpetViewControllerMove dir;
            if (ABS(trans.x) > ABS(trans.y))
            {
                if (direction != ECCarpetHorizontal)
                    return;
                dir = (trans.x > 0) ? ECCarpetMoveDownOrRight : ECCarpetMoveUpOrLeft;
            }
            else
            {
                if (direction != ECCarpetVertical)
                    return;
                dir = (trans.y > 0) ? ECCarpetMoveDownOrRight : ECCarpetMoveUpOrLeft;
            }
            [self moveCarpetInDirection:dir animated:YES];
        }
    }
}

#pragma mark -
#pragma mark Private category implementation

- (CGFloat)unitsDimensionForViewControllerAtIndex:(NSInteger)anIndex 
                                  withOrientation:(UIDeviceOrientation)anOrientation
{
    // TODO sanity checks
    CGSize size = [(NSValue*)[self.viewControllersSizes objectAtIndex:anIndex] CGSizeValue];
    CGFloat dim = UIDeviceOrientationIsLandscape(anOrientation) ? size.width : size.height;
    if (dim <= 1.0)
    {
        dim *= (direction == ECCarpetHorizontal) ? self.view.bounds.size.width : self.view.bounds.size.height;
    }
    return dim;
}

- (CGRect)frameForMainViewControllerConsideringHidden:(UIViewController*)aController
{
    CGRect result = CGRectMake(0, 0, 0, 0);
    NSInteger viewControllersCount = [viewControllers count];
    NSInteger mainControllerIndex = [viewControllers indexOfObject:mainViewController];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    NSInteger considerHiddenIndex = -1; 
    if (aController != nil)
        considerHiddenIndex = [viewControllers indexOfObject:aController];
    CGFloat before = 0, after = 0;
    for (int i = 0; i < viewControllersCount; ++i)
    {
        if (i != considerHiddenIndex
            && !((UIViewController*)[viewControllers objectAtIndex:i]).view.hidden)
        {
            if (i < mainControllerIndex)
                before += [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
            else if (i > mainControllerIndex)
                after += [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
            else if (before != 0)
                break;
        }
    }
    if (direction == ECCarpetHorizontal)
    {
        result.origin.x = before;
        result.size.width = self.view.bounds.size.width - before - after;
        result.size.height = self.view.bounds.size.height;
    }
    else
    {
        result.origin.y = before;
        result.size.width = self.view.bounds.size.width;
        result.size.height = self.view.bounds.size.height - before - after;
    }
    return result;
}

- (CGRect)frameForViewController:(UIViewController *)aController
{
    CGRect result = CGRectMake(0, 0, 0, 0);
    // Main view controller special case (use specific method)
    if (aController == mainViewController)
    {
        return result;
    }
    //
    NSInteger viewControllersCount = [viewControllers count];
    NSInteger mainControllerIndex = [viewControllers indexOfObject:mainViewController];
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    CGFloat origin = 0;
    NSInteger controllerIndex = [viewControllers indexOfObject:aController];
    // Calculate direction independent parameters
    if (controllerIndex < mainControllerIndex)
    {
        for (int i = 0; i < controllerIndex; ++i)
        {
            origin += [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
        }
    }
    else
    {
        origin = (direction == ECCarpetHorizontal) ? self.view.bounds.size.width : self.view.bounds.size.height;
        for (int i = viewControllersCount - 1; i >= controllerIndex; --i)
        {
            origin -= [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
        }
    }
    // Generate direction specific frame
    if (self.direction == ECCarpetHorizontal)
    {
        result.size.width = [self unitsDimensionForViewControllerAtIndex:controllerIndex withOrientation:orientation];
        result.size.height = self.view.bounds.size.height;
        result.origin.x = origin;
    }
    else // vertical
    {
        result.size.width = self.view.bounds.size.width;
        result.size.height = [self unitsDimensionForViewControllerAtIndex:controllerIndex withOrientation:orientation];
        result.origin.y = origin;
    }
    return result;
}

@end
