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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    carpetController = [[ECCarpetViewController alloc] init];

    carpetController.viewControllers = [NSArray arrayWithObjects:
                                        leftFrameController, 
                                        mainFrameController, 
                                        nil];
    carpetController.viewControllersSizes = [NSArray arrayWithObjects:
                                             [NSValue valueWithCGSize:CGSizeMake(0.3, 0.3)], 
                                             [NSValue valueWithCGSize:CGSizeMake(0, 0)], 
                                             nil];
    carpetController.mainViewController = mainFrameController;
    
    [window addSubview:carpetController.view];
    
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc 
{
    [window release];
    [leftFrameController release];
    [mainFrameController release];
    [carpetController release];
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
