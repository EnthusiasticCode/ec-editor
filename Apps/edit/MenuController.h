//
//  MenuController.h
//  edit
//
//  Created by Uri Baghin on 6/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECTripleSplitViewController.h"

@interface MenuController : UIViewController <ECTripleSplitViewControllerDelegate>
- (IBAction)hideSidebar:(id)sender;
- (IBAction)showSidebar:(id)sender;
@end
