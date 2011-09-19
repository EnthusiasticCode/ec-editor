//
//  ACToolController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 10/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppStyle.h"

@class ACToolFiltersView;


@interface ACToolController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UIButton *tabButton;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) IBOutlet ACToolFiltersView *filterContainerView;
@property (nonatomic, strong) IBOutlet UITextField *filterTextField;
@property (nonatomic, strong) IBOutlet UIButton *filterAddButton;

@end
