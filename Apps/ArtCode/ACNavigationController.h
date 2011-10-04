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

@end
