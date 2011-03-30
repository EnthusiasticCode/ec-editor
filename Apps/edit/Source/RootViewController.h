//
//  ProjectBrowser.h
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FileBrowser.h"
#import "FileBrowserDelegate.h"

@interface RootViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, FileBrowser>

@end
