//
//  ACToolPanelController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACToolController.h"

@interface ACToolPanelController : UIViewController

@property (nonatomic, strong) IBOutlet UIView *tabsView;

- (void)addToolWithController:(ACToolController *)toolController tabImage:(UIImage *)tabImage selectedTabImage:(UIImage *)selectedImage;
- (void)updateTabs;

@property (nonatomic, strong) ACToolController *selectedViewController;
- (void)setSelectedViewController:(ACToolController *)controller animated:(BOOL)animated;

@end
