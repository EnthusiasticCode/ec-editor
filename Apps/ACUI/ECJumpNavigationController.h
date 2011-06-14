//
//  ECJumpNavigationController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 09/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ECJumpBar.h"

@interface ECJumpNavigationController : UINavigationController

@property (nonatomic, strong) IBOutlet ECJumpBar *jumpBar;

@end
