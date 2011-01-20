//
//  editAppDelegate.h
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCarpetViewController.h"

@interface editAppDelegate : NSObject <UIApplicationDelegate, ECCarpetViewControllerDelegate> {
    ECCarpetViewController *verticalCarpet, *horizontalCarpet;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end
