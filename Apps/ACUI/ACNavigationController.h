//
//  ACNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"
#import "ECButton.h"
#import "ECPopoverController.h"


@interface ACNavigationController : UIViewController <ECJumpBarDelegate> {
@private
    ECPopoverController *popoverController;
}

#pragma mark Navigation Tools

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;
@property (nonatomic, strong) IBOutlet ECButton *buttonTools;
@property (nonatomic, strong) IBOutlet ECButton *buttonEdit; // TODO remember to use setEdit:animated: and editing of uiviewcontroller

#pragma mark Navigation Methods

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
//- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
