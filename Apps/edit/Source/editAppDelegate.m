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
#import <ECCodeIndexing/ECCodeIndex.h>

@implementation editAppDelegate

@synthesize window = _window;
@synthesize codeView = _codeView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    ECCodeProjectController *rootController;
    [[UINib nibWithNibName:@"CodeProjectController" bundle:nil] instantiateWithOwner:self.window options:nil];
    rootController = (ECCodeProjectController *) self.window.rootViewController;
    [rootController loadProjectFromRootDirectory:[NSURL fileURLWithPath:[[self applicationDocumentsDirectory] stringByAppendingPathComponent:@"edit/"]]];    
    [self.window addSubview:rootController.view];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)dealloc
{
    self.window = nil;
    self.codeView = nil;
    [super dealloc];
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
