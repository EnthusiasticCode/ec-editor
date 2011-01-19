//
//  ECCarpetViewController.m
//  edit
//
//  Created by Nicola Peduzzi on 18/01/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ECCarpetViewController.h"

@interface ECCarpetViewController () 

- (CGRect)frameForViewController:(UIViewController*)aController;

@end

@implementation ECCarpetViewController

@synthesize delegate;
@synthesize viewControllers;
@synthesize mainViewController;
@synthesize direction;

#pragma mark -
#pragma mark UIViewController overloads implementation

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        currentHiddenState = NULL;
    }
    return self;
}
 */

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
    
    for(UIViewController* controller in [viewControllers objectEnumerator])
    {
        if(controller == mainViewController)
        {
            controller.view.frame = root.bounds;
        }
        else
        {
            controller.view.frame = [self frameForViewController:controller];
            controller.view.hidden = YES;
        }
        controller.view.autoresizingMask = root.autoresizingMask;
        [root addSubview:controller.view];
    }

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
    [viewControllers release];
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
    if (aSide == ECCarpetMoveDownOrRight)
    {
        for (UIViewController* controller in [viewControllers objectEnumerator])
        {
            if (controller == mainViewController)
            {
                afterMainController = YES;
                continue;
            }
            if (controller.view.hidden)
            {
                if (toShow == nil)
                    toShow = controller;
            }
            else if (afterMainController)
            {
                toHide = controller;
                break;
            }
        }
    }
    // TODO other side
    //
    if (toHide == nil)
    {
        toShow.view.hidden = NO;
    }
    else
    {
        // TODO animate hiding or do it after animation
        toHide.view.hidden = YES;
    }
    // Animate
    CGRect newFrame = [self frameForViewController:mainViewController];
    [UIView animateWithDuration:1.0 animations:^(void) {
        mainViewController.view.frame = newFrame;
    } completion:^(BOOL finished) {
        // TODO call delegate
    }];
}

- (IBAction)moveCarpetDownRight:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveDownOrRight animated:YES];
}

- (IBAction)moveCarpetUpLeft:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveUpOrLeft animated:YES];
}

#pragma mark -
#pragma mark Private category implementation


- (CGRect)frameForViewController:(UIViewController *)aController
{
    CGRect result = CGRectMake(0, 0, 0, 0);
    NSInteger mainControllerIndex = [viewControllers indexOfObject:mainViewController];
    // Main view controller special case (autosize)
    if (aController == mainViewController)
    {
        CGFloat before = 0, after = 0;
        NSInteger idx = 0;
        for (UIViewController* obj in [viewControllers objectEnumerator])
        {
            if (!obj.view.hidden)
            {
                if (idx < mainControllerIndex)
                    before += (direction == ECCarpetHorizontal) ? obj.view.bounds.size.width : obj.view.bounds.size.height;
                else if (idx > mainControllerIndex)
                    after += (direction == ECCarpetHorizontal) ? obj.view.bounds.size.width : obj.view.bounds.size.height;
                else if (before != 0)
                    break;
            }
            idx++;
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
    }
    // Generic view controller
    else
    {
        CGFloat origin = 0;
        // Calculate direction independent parameters
        if ([viewControllers indexOfObject:aController] < mainControllerIndex)
        {
            for (UIViewController* obj in [viewControllers objectEnumerator])
            {
                if (obj == aController)
                    break;
                origin += (direction == ECCarpetHorizontal) ? obj.view.bounds.size.width : obj.view.bounds.size.height;
            }
        }
        else
        {
            origin = (direction == ECCarpetHorizontal) ? self.view.bounds.size.width : self.view.bounds.size.height;
            for (UIViewController* obj in [viewControllers reverseObjectEnumerator])
            {
                origin -= (direction == ECCarpetHorizontal) ? obj.view.bounds.size.width : obj.view.bounds.size.height;
                if (obj == aController)
                    break;
            }
        }
        // Generate direction specific frame
        if (self.direction == ECCarpetHorizontal)
        {
            result.size.width = aController.view.bounds.size.width;
            result.size.height = self.view.bounds.size.height;
            result.origin.x = origin;
        }
        else // vertical
        {
            result.size.width = self.view.bounds.size.width;
            result.size.height = aController.view.bounds.size.height;
            result.origin.y = origin;
        }
    }
    return result;
}

@end
