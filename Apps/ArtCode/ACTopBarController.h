//
//  ACToolbarController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 17/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ACTopBarToolbar;

@interface ACTopBarController : UIViewController

@property (nonatomic, strong) IBOutlet ACTopBarToolbar *defaultToolbar;
@property (nonatomic, readonly, strong) UIView *currentToolbarView;

- (void)pushToolbarView:(UIView *)toolbarView animated:(BOOL)animated;
- (void)popToolbarViewAnimated:(BOOL)animated;

@property (nonatomic) CGFloat toolbarHeight;
- (void)setToolbarHeight:(CGFloat)toolbarHeight animated:(BOOL)animated;
- (void)resetToolbarHeightAnimated:(BOOL)animated;

@property (nonatomic, strong) IBOutlet UIViewController *contentViewController;
- (void)setContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated;

@end


@interface UIViewController (ACTopBarController)

- (ACTopBarController *)topBarController;

@end