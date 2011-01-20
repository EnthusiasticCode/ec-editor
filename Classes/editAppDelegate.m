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
@synthesize leftFrameController;
@synthesize mainFrameController;
@synthesize rightFrameController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initializing carpet
    carpetController = [[ECCarpetViewController alloc] init];

    carpetController.viewControllers = [NSArray arrayWithObjects:
                                        leftFrameController, 
                                        mainFrameController, 
                                        rightFrameController,
                                        nil];
    carpetController.viewControllersSizes = [NSArray arrayWithObjects:
                                             [NSValue valueWithCGSize:CGSizeMake(0.3, 0.1)], 
                                             [NSValue valueWithCGSize:CGSizeMake(0, 0)], 
                                             [NSValue valueWithCGSize:CGSizeMake(0.3, 0.1)],
                                             nil];
    carpetController.mainViewController = mainFrameController;
    //carpetController.direction = ECCarpetVertical;
    
    // Adding carpet
    [window addSubview:carpetController.view];
    
    // Gestures
    UIPanGestureRecognizer *recognizer = [[UIPanGestureRecognizer alloc] init];
    recognizer.minimumNumberOfTouches = 1;
    recognizer.maximumNumberOfTouches = 1;
    carpetController.gestureRecognizer = recognizer;
    [recognizer release];
    
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc 
{
    [window release];
    [leftFrameController release];
    [mainFrameController release];
    [carpetController release];
    [rightFrameController release];
    [super dealloc];
}

- (IBAction)doStuff:(id)sender 
{
    [carpetController moveCarpetDownRight:sender];
}

- (IBAction)doOtherStuff:(id)sender 
{
    [carpetController moveCarpetUpLeft:sender];
}

@end
