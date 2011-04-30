//
//  MokupControlsViewController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECButton.h"
#import "ECJumpBar.h"
#import "ECPopoverController.h"


@interface MokupControlsViewController : UIViewController <ECJumpBarDelegate> {
    
    ECJumpBar *jumpBar;
    UIViewController *popoverContentViewController;
    UIImageView *imageView;
    UIImageView *imageView2;
    UIImageView *projectImageView;
    
    ECPopoverController *popoverController;
}

@property (nonatomic, retain) IBOutlet ECJumpBar *jumpBar;

@property (nonatomic, retain) IBOutlet UIViewController *popoverContentViewController;

@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIImageView *imageView2;
@property (nonatomic, retain) IBOutlet UIImageView *projectImageView;

- (IBAction)pushToJumpBar:(id)sender;
- (void)jumpBarButtonAction:(id)sender;
- (IBAction)showPopover:(id)sender;

@end
