//
//  FileMap.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowser.h"
#import "ECRelationalTableView.h"

@interface ProjectViewController : UIViewController <FileBrowser, ECRelationalTableViewDataSource, ECRelationalTableViewDelegate>
@property (nonatomic, retain) NSArray *extensionsToShow;
@property (nonatomic, retain) IBOutlet ECRelationalTableView *tableView;
@end
