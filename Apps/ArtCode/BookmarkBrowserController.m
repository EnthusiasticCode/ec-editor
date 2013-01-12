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
  self = [super initWithNibNamed:@"SearchableTableBrowserController" title:@"Bookmarks" searchBarStaticOnTop:![self isMemberOfClass:[BookmarkBrowserController class]]];
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
			// Filter bookmarks
			_filteredItems = [NSMutableArray arrayWithCapacity:bookmarks.count];
			_filteredItemsHitMask = [NSMutableArray arrayWithCapacity:bookmarks.count];
			for (RACTuple *tuple in [bookmarks sortedArrayUsingScoreForAbbreviation:self.searchBar.text extrapolateTargetStringBlock:^NSString *(ArtCodeProjectBookmark *bookmark) {
				return bookmark.name;
			}]) {
				RACTupleUnpack(ArtCodeProjectBookmark *bookmark, NSIndexSet *hitMask) = tuple;
				[(NSMutableArray *)_filteredItems addObject:bookmark];
				if (hitMask != nil) [(NSMutableArray *)_filteredItemsHitMask addObject:hitMask];
			}
			
			if ([_filteredItems count] == 0) {
				if ([self.searchBar.text length]) {
					self.infoLabel.text = @"No bookmarks found.";
				} else {
					self.infoLabel.text = @"The project has no bookmarks.";
				}
			} else {
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

- (void)viewDidLoad {
  [super viewDidLoad];
	[self.hintView removeFromSuperview];
	self.hintView = nil;
  
  if ([self isMemberOfClass:[BookmarkBrowserController class]]) {
		// Tool edit items
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
		
    // Customize subviews
    self.searchBar.placeholder = @"Filter bookmarks";
  }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  ArtCodeLocation *bookmarkLocation = (self.filteredItems)[indexPath.row];
  
  cell.textLabel.text = bookmarkLocation.name;
  cell.textLabelHighlightedCharacters = _filteredItemsHitMask ? _filteredItemsHitMask[indexPath.row] : nil;
  cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (!self.isEditing) {
    ArtCodeProjectBookmark *bookmark = (self.filteredItems)[indexPath.row];
    [self.artCodeTab pushFileURL:bookmark.fileURL withProject:self.artCodeTab.currentLocation.project dataDictionary:@{ @"lineNumber" : @(bookmark.lineNumber)}];
  }
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

@end
