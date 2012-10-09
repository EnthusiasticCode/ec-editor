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

@end
