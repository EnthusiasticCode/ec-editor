//
//  ACQuickFileBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ECFoundation/ECDirectoryPresenter.h>


@interface ACQuickFileBrowserController : UIViewController <UISearchBarDelegate, ECDirectoryPresenterDelegate, UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readonly) UITableView *tableView;

@end
