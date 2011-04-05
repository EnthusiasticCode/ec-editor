//
//  MokupControlsViewController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECMockupButton.h"
#import "ECStackFilterBarController.h"


@interface MokupControlsViewController : UIViewController {
    
    UITextField *aTextField;
    ECStackFilterBarController *stackFilterBarController;
    
}

@property (nonatomic, retain) IBOutlet ECMockupButton *aButton;
@property (nonatomic, retain) IBOutlet UITextField *aTextField;
@property (nonatomic, retain) IBOutlet ECStackFilterBarController *stackFilterBarController;

- (IBAction)doSomething:(id)sender;

@end
