//
//  ECSplitViewControllerTest_AppDelegate.h
//  ECSplitViewControllerTest
//
//  Created by Nicola Peduzzi on 20/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECSplitViewController;


@interface ECSplitViewControllerTest_AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (weak, nonatomic) IBOutlet ECSplitViewController *splitViewController;
- (IBAction)pinSidebar:(id)sender;

@end
