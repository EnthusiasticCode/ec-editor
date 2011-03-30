//
//  FileMap.h
//  edit-single-project
//
//  Created by Uri Baghin on 3/27/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowser.h"

@interface ProjectViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FileBrowser>

@end
