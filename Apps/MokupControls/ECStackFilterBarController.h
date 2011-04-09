//
//  ECStackFilterBarController.h
//  MokupControls
//
//  Created by Nicola Peduzzi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECMockupButton.h"


@interface ECStackFilterBarController : UIViewController {
    
    UIView *backgroundView;
    UITextField *filterTextField;
    NSMutableArray *buttonStack;
}

@property (nonatomic, retain) IBOutlet UIView *backgroundView;
@property (nonatomic, retain) IBOutlet UITextField *filterTextField;

// TODO attach action?
- (void)pushStateButtonWithDescription:(NSString *)description;
- (void)popStateButton;

@end
