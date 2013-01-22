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


#import "HighlightTableViewCell.h"

#import "BezelAlert.h"
#import "NSString+PluralFormat.h"

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>


@implementation BookmarkBrowserController {
@protected
  BOOL _filteredItemsAreValid;
  NSArray *_filteredItems;
}

- (id)init {
  self = [super initWithNibNamed:@"SearchableTableBrowserController" title:@"Bookmarks" searchBarStaticOnTop:![self isMemberOfClass:[BookmarkBrowserController class]]];
  if (!self)
    return nil;
  return self;
}

#pragma mark - Properties

- (NSArray *)filteredItems {
#warning TODO: make this in RAC style when bookmarksWithResultHandler: is re-implemented as .bookmarks
	ASSERT(NO); // This should be
  if (!_filteredItemsAreValid) {
    // Get the new bookmarks
//    [self.artCodeTab.currentLocation.project bookmarksWithResultHandler:^(NSArray *bookmarks) {
//			// Filter bookmarks
//			_filteredItems = [bookmarks sortedArrayUsingScoreForAbbreviation:self.searchBar.text extrapolateTargetStringBlock:^NSString *(ArtCodeProjectBookmark *bookmark) {
//				return bookmark.name;
//			}];
//			
//			if ([_filteredItems count] == 0) {
//				if ([self.searchBar.text length]) {
//					self.infoLabel.text = @"No bookmarks found.";
//				} else {
//					self.infoLabel.text = @"The project has no bookmarks.\nAdd bookmarks by tapping on a line number in a file.";
//				}
//			} else {
//				self.infoLabel.text = @"";
//			}
//      
//      [self.tableView reloadData];
//    }];
    // Set valid even if not valid yet but calculating
    _filteredItemsAreValid = YES;
  }
  return _filteredItems;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if ([self isMemberOfClass:[BookmarkBrowserController class]]) {
		// Tool edit items
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
		
    // Customize subviews
    self.searchBar.placeholder = L(@"Filter bookmarks");
  }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
	RACTupleUnpack(RACTuple *bookmarkTuple, NSIndexSet *hitMask) = self.filteredItems[indexPath.row];
	RACTupleUnpack(RCIOFile *file, NSNumber *lineNumber) = bookmarkTuple;
	
  cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", file.name, lineNumber];
  cell.textLabelHighlightedCharacters = hitMask;
  cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    RACTuple *bookmarkTuple = [self.filteredItems[indexPath.row] first];
		RACTupleUnpack(RCIOFile *file, NSNumber *lineNumber) = bookmarkTuple;
    [self.artCodeTab pushFileURL:file.url dataDictionary:@{ @"lineNumber" : lineNumber }];
  }
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

@end
