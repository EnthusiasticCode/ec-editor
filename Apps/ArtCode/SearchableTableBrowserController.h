//
//  BrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchableTableBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource>

- (id)initWithTitle:(NSString *)title searchBarStaticOnTop:(BOOL)isSearchBarStaticOnTop;

#pragma mark Provide items for the table view

/// Override this property getter to provide filtered items.
@property (nonatomic, readonly, strong) NSArray *filteredItems;

/// Called when the filtered items should be invalidated. Subclasses should call
/// the superclass implementation after invalidating the internal cache.
- (void)invalidateFilteredItems;

#pragma mark Layout objects

/// The search bar used to filter
@property (nonatomic, readonly, strong) UISearchBar *searchBar;

/// The table view that shows the filtered data
@property (nonatomic, readonly, strong) UITableView *tableView;

/// A label that is presented at the bottom of the table view
@property (nonatomic, readonly, strong) UILabel *infoLabel;

/// If not nil, this items will be set when the controller is not in edit mode.
/// This property should be set in loadView.
@property (nonatomic, strong) NSArray *toolNormalItems;

/// If not nil, this items will be set when the controller is in edit mode.
/// This property should be set in loadView.
@property (nonatomic, strong) NSArray *toolEditItems;

@end
