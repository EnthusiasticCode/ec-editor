//
//  ECTexturedPopoverView_ViewController.h
//  ECTexturedPopoverView
//
//  Created by Nicola Peduzzi on 05/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ECTexturedPopoverView;

@interface ECTexturedPopoverView_ViewController : UIViewController
@property (strong, nonatomic) IBOutlet ECTexturedPopoverView *popoverView;
- (IBAction)changePopoverArrowSide:(id)sender;
- (IBAction)changePopoverArrowPosition:(id)sender;

@end
