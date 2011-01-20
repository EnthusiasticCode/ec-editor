//
//  editAppDelegate.h
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCarpetViewController.h"

@interface editAppDelegate : NSObject <UIApplicationDelegate> {

    UIViewController *leftFrameController;
    UIViewController *mainFrameController;
    UIViewController *rightFrameController;
    ECCarpetViewController *carpetController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UIViewController *leftFrameController;
@property (nonatomic, retain) IBOutlet UIViewController *mainFrameController;
@property (nonatomic, retain) IBOutlet UIViewController *rightFrameController;

- (IBAction)doStuff:(id)sender;
- (IBAction)doOtherStuff:(id)sender;

@end
