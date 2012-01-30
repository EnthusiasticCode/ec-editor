//
//  QuickFileBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DirectoryPresenter.h"


@interface QuickFileBrowserController : UIViewController <UISearchBarDelegate, DirectoryPresenterDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) UITableView *tableView;

@end
