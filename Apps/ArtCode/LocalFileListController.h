//
//  BaseFileBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/10/12.
//
//

#import "SearchableTableBrowserController.h"

@class FileSystemDirectory;

@interface LocalFileListController : SearchableTableBrowserController

/// The location shown by the browser
@property (nonatomic, strong) FileSystemDirectory* locationDirectory;

/// An array with the selected items. Items are \c FileSystemItem.
@property (nonatomic, readonly, copy) NSArray *selectedItems;

/// Adds an item to the list that will be presented as non-selectable files with download progress.
/// The signal is expected to yield NSNumbers with percent progress, any other kind of value will be ignored.
/// When the signal completes, the item will be removed.
- (void)addProgressItemWithName:(NSString *)name progressSignal:(RACSignal *)progressSignal;

@end
