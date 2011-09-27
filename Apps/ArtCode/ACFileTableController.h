//
//  ACFileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACNavigationTarget.h"

@class ACToolFiltersView, ACGroup;


@interface ACFileTableController : UIViewController <ACNavigationTarget, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) ACGroup *group;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) IBOutlet ACToolFiltersView *editingToolsView;

@end
