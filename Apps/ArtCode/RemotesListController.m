//
//  RemotesListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemotesListController.h"
#import "SingleTabController.h"

#import "ArtCodeTab.h"
#import "ArtCodeProject.h"
#import "ArtCodeRemote.h"
#import "ArtCodeLocation.h"

#import "NSArray+ScoreForAbbreviation.h"
#import "HighlightTableViewCell.h"
#import "ShapePopoverBackgroundView.h"
#import "NewRemoteViewController.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "BezelAlert.h"

@class SingleTabController, TopBarToolbar;

@interface RemotesListController ()

- (void)_toolAddAction:(id)sender;

@end

@implementation RemotesListController {
  NSArray *_filteredRemotes;
  NSArray *_filteredRemotesHitMasks;
  
  UIPopoverController *_toolAddPopover;
}

- (id)init
{
  self = [super initWithTitle:@"Remotes" searchBarStaticOnTop:NO];
  if (!self)
    return nil;
  
  // RAC
  __weak RemotesListController *this = self;
  
  [RACAbleSelf(self.artCodeTab.currentLocation.project.remotes) subscribeNext:^(id x) {
    [this invalidateFilteredItems];
    [this.tableView reloadData];
  }];
  
  return self;
}

#pragma mark - Properties

- (NSArray *)filteredItems
{ 
  if (!_filteredRemotes)
  {
    if ([self.searchBar.text length] == 0)
    {
      _filteredRemotes = self.artCodeTab.currentLocation.project.remotes.array;
      _filteredRemotesHitMasks = nil;
    }
    else
    {
      NSArray *hitMasks = nil;
      _filteredRemotes = [self.artCodeTab.currentLocation.project.remotes.array sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ArtCodeRemote *element) {
        return element.name;
      }];
      _filteredRemotesHitMasks = hitMasks;
    }
  }
  return _filteredRemotes;
}

- (void)invalidateFilteredItems
{
  _filteredRemotes = nil;
  _filteredRemotesHitMasks = nil;
  [super invalidateFilteredItems];
}

#pragma mark - View lifecycle

- (void)loadView
{
  [super loadView];
  
  // Load the bottom toolbar
  [[NSBundle mainBundle] loadNibNamed:@"BrowserControllerBottomBar" owner:self options:nil];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolAddAction:)]];
  
  self.toolEditItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)]];
  
  self.searchBar.placeholder = @"Filter remotes";
}

- (void)viewDidUnload
{
  _toolAddPopover = nil;
  [super viewDidUnload];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
  return NO;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
  
  ArtCodeRemote *remote = [self.filteredItems objectAtIndex:indexPath.row];
  cell.textLabel.text = remote.name;
  cell.textLabelHighlightedCharacters = _filteredRemotesHitMasks ? [_filteredRemotesHitMasks objectAtIndex:indexPath.row] : nil;
  cell.detailTextLabel.text = [[remote url] absoluteString];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!self.isEditing)
  {
    [self.artCodeTab pushLocation:[[self.filteredItems objectAtIndex:indexPath.row] locationWithPath:@"/"]];
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Action sheed delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet == _toolEditDeleteActionSheet)
  {
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
      self.loading = YES;
      NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
      [self setEditing:NO animated:YES];
      for (NSIndexPath *indexPath in selectedRows) {
        [self.artCodeTab.currentLocation.project removeRemotesObject:[self.filteredItems objectAtIndex:indexPath.row]];
      }
      self.loading = NO;
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"Remote deleted" plural:@"%u remotes deleted" count:[selectedRows count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      [self invalidateFilteredItems];
      [self.tableView reloadData];
    }
  }
}

#pragma mark - Private methods

- (void)_toolAddAction:(id)sender
{
  if (!_toolAddPopover)
  {
    NewRemoteViewController *newRemote = [NewRemoteViewController new];
    newRemote.artCodeTab = self.artCodeTab;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newRemote];
    [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    _toolAddPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
    _toolAddPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
    newRemote.presentingPopoverController = _toolAddPopover;
  }
  [_toolAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

@end
