//
//  DirectoryBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class FileSystemDirectory;

/// Controller used to manage a table view display a drill-down navigation
/// in folders starting from the current project's content folder.
@interface FolderBrowserController : UITableViewController

/// The folder that the browser is currently displaying.
@property (nonatomic, strong) id<RACSignal> currentFolderSignal;

/// A FileSystemDirectory for which to show a message and disable action buttons.
@property (nonatomic, strong) FileSystemDirectory *excludeDirectory;

/// The ArtCodeLocation selected by the user.
@property (nonatomic, strong, readonly) FileSystemDirectory *selectedFolder;

@end
