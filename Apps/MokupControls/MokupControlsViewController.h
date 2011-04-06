//
//  MokupControlsViewController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECMockupButton.h"
#import "ECJumpBar.h"


@interface MokupControlsViewController : UIViewController <ECJumpBarDelegate> {
    
    ECJumpBar *jumpBar;
    UIImageView *imageView;
}

@property (nonatomic, retain) IBOutlet ECMockupButton *aButton;
@property (nonatomic, retain) IBOutlet ECJumpBar *jumpBar;

@property (nonatomic, retain) IBOutlet UIImageView *imageView;

- (IBAction)pushToJumpBar:(id)sender;
- (void)jumpBarButtonAction:(id)sender;

@end
