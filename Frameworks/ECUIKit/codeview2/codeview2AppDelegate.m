//
//  codeview2AppDelegate.m
//  codeview2
//
//  Created by Nicola Peduzzi on 02/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "codeview2AppDelegate.h"


@implementation codeview2AppDelegate
@synthesize window;

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
    [window makeKeyAndVisible];
}

- (void)dealloc {
    [window release];
    [super dealloc];
}
@end
