//
//  editAppDelegate.m
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "editAppDelegate.h"

#import "ECCodeProject.h"
#import "ECCodeProjectController.h"

@implementation editAppDelegate


@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ECCodeProjectController *rootController;
    // iOS 3.2:
    NSArray *bundleContents = [[NSBundle mainBundle] loadNibNamed:@"CodeProjectController" owner:self options:nil];
    rootController = [[bundleContents objectAtIndex:0] retain];
    // iOS 4:
//    [[UINib nibWithNibName:@"CodeProjectController" bundle:nil] instantiateWithOwner:window options:nil];
//    rootController = (ECCodeProjectController *) window.rootViewController;
    // directory must exist
    [rootController loadProject:@"edit" from:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit/"]];
    [window addSubview:rootController.view];
    [window makeKeyAndVisible];
    return YES;
}

- (void)dealloc
{
    self.window = nil;
    [super dealloc];
}

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
