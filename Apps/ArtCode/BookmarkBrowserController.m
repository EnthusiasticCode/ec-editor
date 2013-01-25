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
#import "NSURL+ArtCode.h"
#import "RCIODirectory+ArtCode.h"

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>


@implementation BookmarkBrowserController

- (id)init {
  self = [super initWithNibNamed:@"SearchableTableBrowserController" title:@"Bookmarks" searchBarStaticOnTop:YES];
  if (self == nil) return nil;
	
	[[[[[RACAble(self.artCodeTab.currentLocation.url.projectRootDirectory) map:^(NSURL *projectRootDirectoryURL) {
		return [RCIODirectory itemWithURL:projectRootDirectoryURL];
	}] switchToLatest] map:^(RCIODirectory *projectRootDirectory) {
		return projectRootDirectory.bookmarksSignal;
	}] switchToLatest] toProperty:@keypath(self.filteredItems) onObject:self];
	
  return self;
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
