//
//  DirectoryBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

/// Controller used to manage a table view display a drill-down navigation
/// in folders starting from the current project's content folder.
@interface FolderBrowserController : UITableViewController

/// The folder that the browser is currently displaying.
@property (nonatomic, strong) NSURL *currentFolderURL;

/// The ArtCodeURL selected by the user.
@property (nonatomic, strong, readonly) NSURL *selectedFolderURL;

@end