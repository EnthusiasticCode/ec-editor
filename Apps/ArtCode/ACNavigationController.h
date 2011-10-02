//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECUIKit/ECJumpBar.h>
#import "ACNavigationTarget.h"

@class ACTab;


/// A navigation controller with jump bar and tabs capabilities
@interface ACNavigationController : UIViewController <ECJumpBarDelegate>

@property (nonatomic, strong) ACTab *tab;

@property (nonatomic, strong, readonly) UIViewController<ACNavigationTarget> *contentViewController;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet UIView *topBarView;
@property (nonatomic, strong) IBOutlet UIView *contentView;
@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Head Bar Methods

- (IBAction)editButtonAction:(id)sender;

@end
