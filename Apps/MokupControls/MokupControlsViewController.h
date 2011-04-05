//
//  MokupControlsViewController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 03/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECMockupButton.h"


@interface MokupControlsViewController : UIViewController {
    
}

@property (nonatomic, retain) IBOutlet ECMockupButton *aButton;

- (IBAction)doSomething:(id)sender;
- (IBAction)changeArrows:(id)sender;

@end
