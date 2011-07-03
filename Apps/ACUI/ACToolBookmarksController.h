//
//  ACToolBookmarksController.h
//  ACUI
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACToolBookmarksController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end
