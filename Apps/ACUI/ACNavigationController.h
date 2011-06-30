//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"
#import "ECPopoverController.h"
#import "ECTabBar.h"
#import "ECSwipeGestureRecognizer.h"


@interface ACNavigationController : UIViewController <ECJumpBarDelegate, ECTabBarDelegate> {
@private
    ECPopoverController *popoverController;
    ECTabBar *tabBar;
    
    ECSwipeGestureRecognizer *tabGestureRecognizer;
    UIScrollView *contentScrollView;
}

@property (nonatomic, strong) IBOutlet UIScrollView *contentScrollView;

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet UIButton *buttonTools;
@property (nonatomic, strong) IBOutlet UIButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
//- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

#pragma mark Tab Navigation

@property (nonatomic, strong) IBOutlet ECTabBar *tabBar;


#pragma mark Bar Methods

- (IBAction)toggleTools:(id)sender;
- (IBAction)toggleEditing:(id)sender;

#pragma mark Tab Bar Methods

- (IBAction)toggleTabBar:(id)sender;
- (IBAction)closeTabButtonAction:(id)sender;


- (IBAction)tests:(id)sender;

@end