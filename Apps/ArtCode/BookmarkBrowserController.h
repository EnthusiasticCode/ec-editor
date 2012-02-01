//
//  BookmarkBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BookmarkBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (nonatomic, strong, readonly) UITableView *tableView;

@end
