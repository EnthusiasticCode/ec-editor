//
//  BrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchableTableBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate> {
@protected
    UINavigationController *_modalNavigationController;
    UIActionSheet *_toolEditDeleteActionSheet;
}

- (id)initWithTitle:(NSString *)title searchBarStaticOnTop:(BOOL)isSearchBarStaticOnTop;

#pragma mark Provide items for the table view

/// Override this property getter to provide filtered items.
@property (nonatomic, readonly, strong) NSArray *filteredItems;

/// Called when the filtered items should be invalidated.
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

/// A bottom toolbar to be displayed statically on the view. This view is loaded usually via a nib in loadView.
@property (strong, nonatomic) IBOutlet UIView *bottomToolBar;

#pragma mark Common actions

/// Shows a confirmation button to confirm the deletion.
/// Subclasses should override the action sheed delegate to modify the behaviour of the confirmation button.
- (IBAction)toolEditDeleteAction:(id)sender;

/// Pushes on the current tab an URL based on the sender's tag.
/// 0 for top project directory, 1 for bookmarks and 2 for remotes
- (IBAction)toolPushUrlForTagAction:(id)sender;

#pragma mark Modal navigation

/// Shows a modal navigation controller and adds a cancel button to the left of the given view controller. The cancel button will invoke modalNavigationControllerDismissAction:.
- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController completion:(void(^)())completion;
- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController;
- (void)modalNavigationControllerDismissAction:(id)sender;

@end

/// Appearance customization superclass
@interface BottomToolBarButton : UIButton
@end
