//
//  ACProjectsTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ACApplication, ACTab;

@interface ACProjectTableController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSURL *projectsDirectory;

@property (nonatomic, strong) ACTab *tab;

@end
