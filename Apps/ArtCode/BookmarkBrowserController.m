//
//  BookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkBrowserController.h"
#import "SingleTabController.h"
#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"

#import "ACProject.h"

#import "HighlightTableViewCell.h"

#import "BezelAlert.h"
#import "NSString+PluralFormat.h"



@implementation BookmarkBrowserController {
@protected
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMask;
}

- (id)init
{
  self = [super initWithTitle:@"Bookmarks" searchBarStaticOnTop:![self isMemberOfClass:[BookmarkBrowserController class]]];
  if (!self)
    return nil;
  return self;
}

#pragma mark - Properties

- (NSArray *)filteredItems
{
  if (!_filteredItems)
  {
    if ([self.searchBar.text length])
    {
      NSArray *hitMasks = nil;
      _filteredItems = [self.artCodeTab.currentProject.bookmarks sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ACProjectFileBookmark *bookmark) {
        return [bookmark description];
      }];
      _filteredItemsHitMask = hitMasks;
      
      if ([_filteredItems count] == 0)
        self.infoLabel.text = @"No bookmarks found.";
    }
    else
    {
      _filteredItems = [self.artCodeTab.currentProject.bookmarks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj1 description] compare:[obj2 description]];
      }];
      _filteredItemsHitMask = nil;
      
      if ([_filteredItems count] == 0)
        self.infoLabel.text = @"The project has no bookmarks.";
    }
    
    if ([_filteredItems count] != 0)
      self.infoLabel.text = @"";
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems
{
  _filteredItemsHitMask = nil;
  _filteredItems = nil;
}

#pragma mark - View lifecycle

- (void)loadView
{
  [super loadView];
  
  if ([self isMemberOfClass:[BookmarkBrowserController class]])
  {
    // Tool edit items
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
    
    // Customize subviews
    self.searchBar.placeholder = @"Filter bookmarks";
    
    // Load the bottom toolbar
    [[NSBundle mainBundle] loadNibNamed:@"BrowserControllerBottomBar" owner:self options:nil];
  }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  ACProjectFileBookmark *bookmark = [self.filteredItems objectAtIndex:indexPath.row];
  
  cell.textLabel.text = [bookmark description];
  cell.textLabelHighlightedCharacters = _filteredItemsHitMask ? [_filteredItemsHitMask objectAtIndex:indexPath.row] : nil;
  //    cell.detailTextLabel.text = bookmark.note;
  cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!self.isEditing)
  {
    [self.artCodeTab pushURL:[[self.filteredItems objectAtIndex:indexPath.row] artCodeURL]];
  }
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if (actionSheet == _toolEditDeleteActionSheet)
  {
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
      self.loading = YES;
      NSArray *selectedRows = self.tableView.indexPathsForSelectedRows;
      [self setEditing:NO animated:YES];
      for (NSIndexPath *indexPath in selectedRows)
      {
        ACProjectFileBookmark *bookmark = [self.filteredItems objectAtIndex:indexPath.row];
        [bookmark.file removeBookmark:bookmark];
      }
      self.loading = NO;
      [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:@"Bookmark deleted" plural:@"%u bookmarks deleted" count:[selectedRows count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
      [self invalidateFilteredItems];
      [self.tableView reloadData];
    }
  }
}

@end
