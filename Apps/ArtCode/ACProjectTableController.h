//
//  ACProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNavigationTarget.h"
@class ACApplication, ACTab;

@interface ACProjectTableController : UITableViewController <ACNavigationTarget, UITextFieldDelegate>

@property (nonatomic, strong) ACApplication *application;

@property (nonatomic, strong) ACTab *tab;

@end
