//
//  RootController.h
//  edit
//
//  Created by Uri Baghin on 6/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RootController : UIViewController
@property (nonatomic, strong) IBOutlet UIView *menuView;
@property (nonatomic, strong) IBOutlet UIView *sidebarView;
@property (nonatomic, strong) IBOutlet UIView *mainView;
@property (nonatomic, getter = isSidebarHidden) BOOL sidebarHidden;
- (void)setSidebarHidden:(BOOL)sidebarHidden animated:(BOOL)animated;
- (IBAction)hideSidebar:(id)sender;
- (IBAction)showSidebar:(id)sender;
@end
