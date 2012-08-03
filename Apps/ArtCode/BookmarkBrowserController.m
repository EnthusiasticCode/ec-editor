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

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"

#import "ArtCodeProject.h"

#import "HighlightTableViewCell.h"

#import "BezelAlert.h"
#import "NSString+PluralFormat.h"



@implementation BookmarkBrowserController {
@protected
  BOOL _filteredItemsAreValid;
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
  if (!_filteredItemsAreValid) {
    // Get the new bookmarks
    [self.artCodeTab.currentLocation.project bookmarksWithResultHandler:^(NSArray *bookmarks) {
      if ([self.searchBar.text length]) {
        // Filter bookmarks
        NSArray *hitMasks = nil;
        _filteredItems = [bookmarks sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ArtCodeProjectBookmark *bookmark) {
          return bookmark.name;
        }];
        _filteredItemsHitMask = hitMasks;
        
        if ([_filteredItems count] == 0) {
          self.infoLabel.text = @"No bookmarks found.";
        }
      } else {
        // Sort bookmarks
        _filteredItems = [bookmarks sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
          return [[obj1 name] compare:[obj2 name]];
        }];
        _filteredItemsHitMask = nil;
        
        if ([_filteredItems count] == 0) {
          self.infoLabel.text = @"The project has no bookmarks.";
        }
      }
      
      if ([_filteredItems count] != 0) {
        self.infoLabel.text = @"";
      }
      
      [self.tableView reloadData];
    }];
    // Set valid even if not valid yet but calculating
    _filteredItemsAreValid = YES;
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems {
  _filteredItemsAreValid = NO;
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
  
  ArtCodeLocation *bookmarkLocation = [self.filteredItems objectAtIndex:indexPath.row];
  
  cell.textLabel.text = bookmarkLocation.name;
  cell.textLabelHighlightedCharacters = _filteredItemsHitMask ? [_filteredItemsHitMask objectAtIndex:indexPath.row] : nil;
  cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!self.isEditing) {
    ArtCodeProjectBookmark *bookmark = [self.filteredItems objectAtIndex:indexPath.row];
    [self.artCodeTab pushFileURL:bookmark.fileURL withProject:self.artCodeTab.currentLocation.project lineNumber:bookmark.lineNumber];
  }
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

@end
