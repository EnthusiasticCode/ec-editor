//
//  ACUITestViewController.h
//  ArtCodeUITest
//
//  Created by Nicola Peduzzi on 16/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACUITestToolbar;

@interface ACUITestViewController : UIViewController

@property (nonatomic, strong) IBOutlet ACUITestToolbar *barView;

@property (nonatomic, strong) IBOutlet UIViewController *contentViewController;
- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;

@end
