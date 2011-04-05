//
//  FileMap.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowser.h"
#import "ECRelationalTableViewDataSource.h"
#import "ECRelationalTableViewDelegate.h"

@interface ProjectViewController : UIViewController <FileBrowser, ECRelationalTableViewDataSource, ECRelationalTableViewDelegate>
@property (nonatomic, retain) NSArray *extensionsToShow;
@end
