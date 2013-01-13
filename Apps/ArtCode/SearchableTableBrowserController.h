//
//  BrowserController.h
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RACSubject;

@interface SearchableTableBrowserController : UIViewController <UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

- (id)initWithNibNamed:(NSString *)nibName title:(NSString *)title searchBarStaticOnTop:(BOOL)isSearchBarStaticOnTop;

#pragma mark Provide items for the table view

/// Override this property getter to provide filtered items.
@property (nonatomic, copy) NSArray *filteredItems;

#pragma mark Layout objects

/// Indicate if the searchbar should be fixed on top instead of as the table header.
@property (nonatomic, readonly) BOOL isSearchBarStaticOnTop;

/// The search bar used to filter
@property (nonatomic, readonly, weak) UISearchBar *searchBar;

/// The table view that shows the filtered data
@property (nonatomic, readonly, weak) UITableView *tableView;

/// A label that is presented at the bottom of the table view
@property (nonatomic, readonly, weak) UILabel *infoLabel;

/// If not nil, this items will be used when the controller is not in edit mode.
@property (nonatomic, strong) NSArray *toolNormalItems;

/// If not nil, this items will be used when the controller is in edit mode.
@property (nonatomic, strong) NSArray *toolEditItems;

/// A bottom toolbar to be displayed statically on the view.
@property (nonatomic, weak) IBOutlet UIView *bottomToolBar;

#pragma mark Common actions

/// Shows a confirmation button to confirm the deletion.
/// Subclasses should override the action sheed delegate to modify the behaviour of the confirmation button.
- (IBAction)toolEditDeleteAction:(id)sender;

/// Used to see if an action sheet is the one opened by toolEditDeleteAction:
- (BOOL)isToolEditDeleteActionSheet:(UIActionSheet *)actionSheet;

/// Pushes on the current tab an URL based on the sender's tag.
/// 0 for top project directory, 1 for bookmarks and 2 for remotes
- (IBAction)toolPushUrlForTagAction:(id)sender;

#pragma mark Modal navigation

@property (nonatomic, strong) UINavigationController *modalNavigationController;

/// Shows a modal navigation controller and adds a cancel button to the left of the given view controller. The cancel button will invoke modalNavigationControllerDismissAction:.
- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController completion:(void(^)())completion;
- (void)modalNavigationControllerPresentViewController:(UIViewController *)viewController;
- (void)modalNavigationControllerDismissAction:(id)sender;

#pragma mark Reactive subjects

/// A subject that pushes the search bar text when it's updated.
@property (readonly, nonatomic) RACSubject *searchBarTextSubject;

@end

/// Appearance customization superclass
@interface BottomToolBarButton : UIButton
@end
