//
//  BaseFileBrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/10/12.
//
//

#import "SearchableTableBrowserController.h"

@interface LocalFileListController : SearchableTableBrowserController

/// The location shown by the browser
@property (nonatomic, strong) NSURL* locationURL;

/// An array with the selected items. Items are \c NSURL.
@property (nonatomic, readonly, copy) NSArray *selectedItems;

/// Adds an item to the list that will be presented as non-selectable files with download progress.
/// The subscribable is expected to yield NSNumbers with percent progress, any other kind of value will be ignored.
/// When the subscribable completes, the item will be removed.
- (void)addProgressItemWithURL:(NSURL *)url progressSubscribable:(RACSubscribable *)progressSubscribable;

@end
