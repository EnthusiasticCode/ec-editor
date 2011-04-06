//
//  MokupControlsViewController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECMockupButton.h"
#import "ECJumpBarView.h"


@interface MokupControlsViewController : UIViewController {
    
    ECJumpBarView *jumpBar;
}

@property (nonatomic, retain) IBOutlet ECMockupButton *aButton;
@property (nonatomic, retain) IBOutlet ECJumpBarView *jumpBar;

- (IBAction)pushToJumpBar:(id)sender;

@end
