//
//  ACToolPanelController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACToolPanelController : UIViewController

@property (nonatomic, strong) IBOutlet UIView *tabsView;

@property (nonatomic, strong) UIViewController *selectedViewController;
- (void)setSelectedViewController:(UIViewController *)controller animated:(BOOL)animated;

@end
