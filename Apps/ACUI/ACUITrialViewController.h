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
#import "ECJumpBar.h"

@interface ACUITrialViewController : UIViewController <ECJumpBarDelegate> {
    ECPopoverController *popoverController;
    UIViewController *popoverContentController;
}

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;

- (IBAction)showPopover:(id)sender;
- (IBAction)pushToJumpBar:(id)sender;

@end
