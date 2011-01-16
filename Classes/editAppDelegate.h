//
//  editAppDelegate.h
//  edit
//
//  Created by Uri Baghin on 1/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECCodeView.h"

@interface editAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    ECCodeView *codeEditor;
    UIViewController *mainViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet ECCodeView *codeEditor;


@end
