//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

@implementation editAppDelegate
@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    UIColor panelsColor = [UIColor colorWithRed:58/255.0 green:58/255.0 blue:60/255.0 alpha:1.0];
    
    // Initializing vertical carpet
    verticalCarpet = [[ECCarpetViewController alloc] init];

    verticalCarpet.viewControllers = [NSArray arrayWithObjects:
                                        [[UIViewController alloc] initWithNibName:@"EditorNavigation" bundle:nil], 
                                        [[UIViewController alloc] initWithNibName:@"EditorMain" bundle:nil], 
                                        [[UIViewController alloc] initWithNibName:@"EditorSplitter" bundle:nil],
                                        nil];
    verticalCarpet.viewControllersSizes = [NSArray arrayWithObjects:
                                             [NSValue valueWithCGSize:CGSizeMake(60, 60)], 
                                             [NSValue valueWithCGSize:CGSizeMake(0, 0)], 
                                             [NSValue valueWithCGSize:CGSizeMake(60, 60)],
                                             nil];
    verticalCarpet.mainViewController = [verticalCarpet.viewControllers objectAtIndex:1];
    verticalCarpet.direction = ECCarpetVertical;
    verticalCarpet.delegate = self;
    
    // Initializing horizontal carpet
    horizontalCarpet = [[ECCarpetViewController alloc] init];
    
    horizontalCarpet.viewControllers = [NSArray arrayWithObjects:
                                      [[UIViewController alloc] initWithNibName:@"EditorBrowser" bundle:nil], 
                                      verticalCarpet, 
                                      [[UIViewController alloc] initWithNibName:@"EditorInfo" bundle:nil],
                                      nil];
    horizontalCarpet.viewControllersSizes = [NSArray arrayWithObjects:
                                           [NSValue valueWithCGSize:CGSizeMake(320, 320)], 
                                           [NSValue valueWithCGSize:CGSizeMake(0, 0)], 
                                           [NSValue valueWithCGSize:CGSizeMake(320, 320)],
                                           nil];
    horizontalCarpet.mainViewController = [horizontalCarpet.viewControllers objectAtIndex:1];
    horizontalCarpet.direction = ECCarpetHorizontal;
    horizontalCarpet.delegate = self;
    
    // DEBUG
    horizontalCarpet.view.backgroundColor = [UIColor redColor];
    
    // Adding carpet
    [window addSubview:horizontalCarpet.view];
    
    // Gestures
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] init];
    recognizer.minimumNumberOfTouches = 1;
    recognizer.maximumNumberOfTouches = 1;
    verticalCarpet.gestureRecognizer = recognizer;
    horizontalCarpet.gestureRecognizer = recognizer;
    [recognizer release];
    
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc 
{
    [verticalCarpet release];
    [horizontalCarpet release];
    [window release];
    [super dealloc];
}

- (BOOL)carpetViewController:(ECCarpetViewController *)cvc 
                  willMoveTo:(ECCarpetViewControllerMove)aDirection 
       showingViewController:(UIViewController *)aShowableViewController 
        hidingViewController:(UIViewController *)aHidableViewController
{
    return YES;
}

- (void)carpetViewController:(ECCarpetViewController *)cvc 
                   didMoveTo:(ECCarpetViewControllerMove)aDirection 
       showingViewController:(UIViewController *)aShowableViewController 
        hidingViewController:(UIViewController *)aHidableViewController
{
    if (aShowableViewController != nil)
    {
        if (cvc == horizontalCarpet)
        {
            [verticalCarpet resetCarpetWithDuration:0.1];
        }
        else if (cvc == verticalCarpet)
        {
            [horizontalCarpet resetCarpetWithDuration:0.1];
        }
    }
}
@end
