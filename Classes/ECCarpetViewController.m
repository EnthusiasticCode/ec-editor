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

// TODO remove redundant method?
// Return YES if the given view controller's view is to be considered visible.
// Another index can be specified to switch the result if anIndex == switchedIndex
- (BOOL)shouldConsiderViewControllerAtIndex:(NSInteger)anIndex
                          switchedIfAtIndex:(NSInteger)switchedIndex;

// Return the frame that the view controller at the specified index should
// have in the current state. Another index can be passed to generate frames 
// as if the corresponding view controller's view visible state was switched.
- (CGRect)frameForViewControllerAtIndex:(NSInteger)anIndex 
              withSwitchedStateForIndex:(NSInteger)switchIndex;

@end

@implementation ECCarpetViewController

@synthesize delegate;
@synthesize viewControllers;
@synthesize mainControllerIndex;
@synthesize viewControllersSizes;
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
    
    UIViewController * controller;
    for (int i = 0; i != [viewControllers count]; ++i)
    {
        controller = (UIViewController*)[viewControllers objectAtIndex:i];
        if (i == self.mainControllerIndex)
        {
            controller.view.frame = root.bounds;
        }
        else
        {
            controller.view.hidden = YES;
            controller.view.frame = [self frameForViewControllerAtIndex:i 
                                              withSwitchedStateForIndex:-1];
        }
        controller.view.autoresizingMask = root.autoresizingMask;
        [root addSubview:controller.view];
//        [root bringSubviewToFront:]
    }
    
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
    [viewControllersSizes release];
    [super dealloc];
}

#pragma mark -
#pragma mark Custom controller messages implementation

- (void)moveCarpetInDirection:(ECCarpetViewControllerMove)aSide 
                     animated:(BOOL)doAnimation
{
    // TODO call delegate's methods
    // Retrieve view controller to hide/show
    NSInteger viewControllerToSwitch = -1;
    int i;
    NSInteger viewControllersCount = [viewControllers count];
    if(aSide == ECCarpetMoveUpOrLeft)
    {
        NSInteger count = MIN(mainControllerIndex, viewControllersCount);
        for(i = 0; i < count; ++i)
        {
            if(!((UIViewController*)[viewControllers objectAtIndex:i]).view.hidden)
            {
                viewControllerToSwitch = i;
                break;
            }
        }
        if (viewControllersCount != -1)
        {
            for(; i < viewControllersCount; ++i)
            {
                if(((UIViewController*)[viewControllers objectAtIndex:i]).view.hidden)
                {
                    viewControllerToSwitch = i;
                    break;
                }
            }
        }
    }
    else
    {
        NSInteger count = MAX(mainControllerIndex - 1, 0);
        for(i = viewControllersCount; i >= count; --i)
        {
            if(!((UIViewController*)[viewControllers objectAtIndex:i]).view.hidden)
            {
                viewControllerToSwitch = i;
                break;
            }
        }
        if (viewControllersCount != -1)
        {
            for(; i >= 0; --i)
            {
                if(((UIViewController*)[viewControllers objectAtIndex:i]).view.hidden)
                {
                    viewControllerToSwitch = i;
                    break;
                }
            }
        }
    }
    // Transition to new disposition
}

- (IBAction)moveCarpetDownRight:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveDownOrRight animated:YES];
}

- (IBAction)moveCarpetUpLeft:(id)sender
{
    [self moveCarpetInDirection:ECCarpetMoveDownOrRight animated:YES];
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
        CGFloat viewdim = 
        self.direction == ECCarpetHorizontal 
            ? self.view.bounds.size.width
            : self.view.bounds.size.height;
        dim *= viewdim;
    }
    return dim;
}

- (BOOL)shouldConsiderViewControllerAtIndex:(NSInteger)anIndex 
                          switchedIfAtIndex:(NSInteger)switchedIndex
{
    // TODO sanity checks
    BOOL hidden = ((UIViewController*)[viewControllers objectAtIndex:anIndex]).view.hidden;
    // TODO use xor?
    return anIndex == switchedIndex ? hidden : !hidden;
}

- (CGRect)frameForViewControllerAtIndex:(NSInteger)anIndex
              withSwitchedStateForIndex:(NSInteger)switchIndex
{
    // TODO cache resulting CGRect in array?
    // FIX dont assume sizes count == controllers count
    CGRect result = CGRectMake(0, 0, 0, 0);
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    // Main view controller special case (autosize)
    if (anIndex == mainControllerIndex)
    {
        CGFloat before = 0, after = 0;
        for (int i = 0; i != [viewControllersSizes count]; ++i)
            if ([self shouldConsiderViewControllerAtIndex:i switchedIfAtIndex:switchIndex])
        {
            if (i < mainControllerIndex)
                before += [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
            else if (i > mainControllerIndex)
                after += [self unitsDimensionForViewControllerAtIndex:i withOrientation:orientation];
        }
        if (self.direction == ECCarpetHorizontal)
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
        CGFloat sizeDirection = 0;
        CGFloat origin = 0;
        // Calculate direction independent parameters
        if ([self shouldConsiderViewControllerAtIndex:anIndex switchedIfAtIndex:switchIndex])
        {
            sizeDirection = [self unitsDimensionForViewControllerAtIndex:anIndex 
                                                         withOrientation:orientation];
            if (anIndex < mainControllerIndex)
            {
                for (int i = 0; i != anIndex; ++i) 
                    if ([self shouldConsiderViewControllerAtIndex:i switchedIfAtIndex:switchIndex])
                    {
                        origin += [self unitsDimensionForViewControllerAtIndex:i 
                                                               withOrientation:orientation];
                    }
            }
            else
            {
                origin -= sizeDirection;
                for (int i = [viewControllersSizes count] - 1; i != anIndex; --i)
                    if ([self shouldConsiderViewControllerAtIndex:i switchedIfAtIndex:switchIndex])
                    {
                        origin -= [self unitsDimensionForViewControllerAtIndex:i 
                                                               withOrientation:orientation];
                    }
            }
        }
        // Generate direction specific frame
        if (self.direction == ECCarpetHorizontal)
        {
            result.size.width = sizeDirection;
            result.size.height = self.view.bounds.size.height;
            if (anIndex > mainControllerIndex)
                origin += self.view.bounds.size.width;
            result.origin.x = origin;
        }
        else // vertical
        {
            result.size.width = self.view.bounds.size.width;
            result.size.height = sizeDirection;
            if (anIndex > mainControllerIndex)
                origin += self.view.bounds.size.height;
            result.origin.y = origin;
        }
    }
    return result;
}

@end
