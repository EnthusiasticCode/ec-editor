//
//  RemotesListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemotesListController.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeRemote.h"
#import "BezelAlert.h"
#import "HighlightTableViewCell.h"
#import "ImagePopoverBackgroundView.h"
#import "NewRemoteViewController.h"
#import "NSString+PluralFormat.h"
#import "SingleTabController.h"
#import "UIViewController+Utilities.h"
#import "RACSignal+ScoreForAbbreviation.h"


@class SingleTabController, TopBarToolbar;

@implementation RemotesListController {
  UIPopoverController *_toolAddPopover;
}

- (id)init {
  self = [super initWithNibNamed:@"SearchableTableBrowserController" title:L(@"Remotes") searchBarStaticOnTop:NO];
  if (!self)
    return nil;
  
  // RAC
	@weakify(self);
	
  [[[[RACAble(self.artCodeTab.currentLocation.project.remotes) map:^(NSOrderedSet *remoteSet) {
		return remoteSet.array;
	}] filterArraySignalByAbbreviation:self.searchBarTextSubject extrapolateTargetStringBlock:^(ArtCodeRemote *remote) {
		return remote.name;
	}] doNext:^(NSArray *filteredRemotes) {
		@strongify(self);
		if (filteredRemotes.count == 0) {
			if (self.searchBar.text.length == 0) {
				self.infoLabel.text = L(@"The project has no remotes. Use the + button to add a new one.");
			} else {
				self.infoLabel.text = L(@"No remotes found.");
			}
		} else {
			self.infoLabel.text = @"";
		}
	}] toProperty:@keypath(self.filteredItems) onObject:self];
  
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
	
	self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolAddAction:)]];
  
  self.toolEditItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)]];
	
  self.searchBar.placeholder = @"Filter remotes";
}

- (void)didReceiveMemoryWarning {
  _toolAddPopover = nil;
  [super didReceiveMemoryWarning];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar {
  return NO;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
  
	RACTupleUnpack(ArtCodeRemote *remote, NSIndexSet *hitMask) = self.filteredItems[indexPath.row];
  cell.textLabel.text = remote.name;
  cell.textLabelHighlightedCharacters = hitMask;
  cell.detailTextLabel.text = [[remote url] absoluteString];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    ArtCodeRemote *remote = [self.filteredItems[indexPath.row] first];
    [self.artCodeTab pushRemotePath:remote.path ?: @"" withRemote:remote];
  }
  
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Action sheed delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if ([self isToolEditDeleteActionSheet:actionSheet]) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
      self.loading = YES;
      NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
      [self setEditing:NO animated:YES];
      for (NSIndexPath *indexPath in selectedRows) {
        NSMutableOrderedSet *remotes = [self.artCodeTab.currentLocation.project mutableOrderedSetValueForKey:@"remotes"];
        ArtCodeRemote *remote = [self.filteredItems[indexPath.row] first];
        [remotes removeObject:remote];
        [remote.managedObjectContext deleteObject:remote];
      }
      self.loading = NO;
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"Remote deleted" plural:@"%u remotes deleted" count:[selectedRows count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      [self invalidateFilteredItems];
      [self.tableView reloadData];
    }
  }
}

#pragma mark - Private methods

- (void)_toolAddAction:(id)sender {
  if (!_toolAddPopover) {
    NewRemoteViewController *newRemote = [[NewRemoteViewController alloc] init];
    newRemote.artCodeTab = self.artCodeTab;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newRemote];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    _toolAddPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    _toolAddPopover.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
    newRemote.presentingPopoverController = _toolAddPopover;
  }
  [_toolAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

@end
