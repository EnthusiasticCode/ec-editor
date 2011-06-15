//
//  ACUITrialViewController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 14/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECPopoverController.h"
#import "ECButton.h"

@interface ACUITrialViewController : UIViewController {
    ECPopoverController *popoverController;
    UIViewController *popoverContentController;
}

- (IBAction)showPopover:(id)sender;

@end
