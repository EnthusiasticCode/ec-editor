//
//  ACQuickBookmarkBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ACQuickBookmarkBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) UITableView *tableView;

@end
