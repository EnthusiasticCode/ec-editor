//
//  ACFileTableController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ACToolTarget.h"

@class ACToolFiltersView;


@interface ACFileTableController : UIViewController <ACToolTarget, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) IBOutlet ACToolFiltersView *editingToolsView;

@end
