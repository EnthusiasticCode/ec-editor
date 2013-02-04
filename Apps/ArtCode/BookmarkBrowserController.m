//
//  BookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 01/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BookmarkBrowserController.h"
#import "SingleTabController.h"
#import "NSString+ScoreForAbbreviation.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"


#import "HighlightTableViewCell.h"

#import "BezelAlert.h"
#import "NSString+PluralFormat.h"
#import "NSURL+ArtCode.h"
#import "RCIOItem+ArtCode.h"

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>

@interface BookmarkBrowserController ()

@property (nonatomic, strong) NSArray *bookmarks;

@end

@implementation BookmarkBrowserController

- (id)init {
  self = [super initWithNibNamed:@"SearchableTableBrowserController" title:@"Bookmarks" searchBarStaticOnTop:![self isMemberOfClass:BookmarkBrowserController.class]];
  if (self == nil) return nil;
	
	[[[[[[RACAble(self.artCodeTab.currentLocation) map:^(ArtCodeLocation *location) {
		return [RCIODirectory itemWithURL:location.url.projectRootDirectory];
	}] switchToLatest] map:^(RCIODirectory *projectRootDirectory) {
		return projectRootDirectory.bookmarksSignal;
	}] switchToLatest] catchTo:RACSignal.empty] toProperty:@keypath(self.bookmarks) onObject:self];
	
	[[[[RACSignal combineLatest:@[ RACBind(self.bookmarks), [self.searchBarTextSubject startWith:nil] ] reduce:^(NSArray *bookmarks, NSString *filter) {
		if (filter.length == 0) {
			NSMutableArray *filteredItems = [NSMutableArray array];
			for (RACTuple *bookmarkTuple in bookmarks) {
				RACTupleUnpack(RCIOFile *file, NSIndexSet *bookmarkedLines) = bookmarkTuple;
				[bookmarkedLines enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					[filteredItems addObject:[RACTuple tupleWithObjects:file, @(idx), RACTupleNil.tupleNil, nil]];
				}];
			}
			return [RACSignal return:filteredItems];
		}
		
		NSMutableArray *scoredBookmarksSignals = [NSMutableArray arrayWithCapacity:bookmarks.count];
		for (RACTuple *bookmarkTuple in bookmarks) {
			RACTupleUnpack(RCIOFile *file, NSIndexSet *bookmarkedLines) = bookmarkTuple;
			[scoredBookmarksSignals addObject:[file.nameSignal map:^(NSString *name) {
				NSIndexSet *hitMask = nil;
				float score = [name scoreForAbbreviation:filter hitMask:&hitMask];
				return [RACTuple tupleWithObjects:file, bookmarkedLines ?: RACTupleNil.tupleNil, @(score), hitMask ?: RACTupleNil.tupleNil,  nil];
			}]];
		}
		return [[RACSignal combineLatest:scoredBookmarksSignals] map:^(RACTuple *scoredBookmarks) {
			NSMutableArray *scoredBookmarksArray = [NSMutableArray arrayWithCapacity:scoredBookmarks.count];
			for (RACTuple *scoredBookmark in scoredBookmarks) {
				RACTupleUnpack(RCIOFile *file, NSIndexSet *bookmarkedLines, NSNumber *score, NSIndexSet *hitMask __attribute__((unused))) = scoredBookmark;
				if (file.url == nil || bookmarkedLines.count == 0 || score.floatValue == 0.0) continue;
				[scoredBookmarksArray addObject:scoredBookmark];
			}
			[scoredBookmarksArray sortUsingComparator:^NSComparisonResult(RACTuple *scoredBookmark1, RACTuple *scoredBookmark2) {
				return [scoredBookmark1.third compare:scoredBookmark2.third];
			}];
			NSMutableArray *filteredItems = [NSMutableArray array];
			for (RACTuple *scoredBookmark in scoredBookmarksArray) {
				RACTupleUnpack(RCIOFile *file, NSIndexSet *bookmarkedLines, NSNumber *score __attribute__((unused)), NSIndexSet *hitMask) = scoredBookmark;
				[bookmarkedLines enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
					[filteredItems addObject:[RACTuple tupleWithObjects:file, @(idx), hitMask ?: RACTupleNil.tupleNil, nil]];
				}];
			}
			return filteredItems;
		}];
	}] switchToLatest] catchTo:RACSignal.empty] toProperty:@keypath(self.filteredItems) onObject:self];
	
  return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
  [super viewDidLoad];
  
  if ([self isMemberOfClass:BookmarkBrowserController.class]) {
		// Tool edit items
    self.toolEditItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(toolEditDeleteAction:)], nil];
		
    // Customize subviews
    self.searchBar.placeholder = L(@"Filter bookmarks");
  }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
	RACTupleUnpack(RCIOFile *file, NSNumber *lineNumber, NSIndexSet *hitMask) = self.filteredItems[indexPath.row];
	
  cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", file.name, lineNumber];
  cell.textLabelHighlightedCharacters = hitMask;
  cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (!self.isEditing) {
    RACTupleUnpack(RCIOFile *file, NSNumber *lineNumber, NSIndexSet *hitMask __attribute__((unused))) = self.filteredItems[indexPath.row];
    [self.artCodeTab pushFileURL:file.url dataDictionary:@{ @"lineNumber" : lineNumber }];
  }
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

@end
