//
//  DirectoryBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FolderBrowserController.h"

#import "ArtCodeTab.h"
#import <ReactiveCocoaIO/ReactiveCocoaIO.h>
#import "RCIOItemCell.h"
#import "NSString+PluralFormat.h"
#import "UIImage+AppStyle.h"

@interface FolderBrowserController ()

@property (nonatomic, strong) RCIODirectory *selectedFolder;
@property (nonatomic, strong) NSArray *currentFolderSubfolders;
@property (nonatomic) BOOL hideExcludeMessage;

@end

#pragma mark

@implementation FolderBrowserController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  
  // RAC
	RACSignal *tableView = RACAbleWithStart(self.tableView);
	RACSignal *currentFolder = [RACAble(self.currentFolderSignal) switchToLatest];
	
	// Excluded folder state
	RACSignal *shouldEnableSignal = [[RACSignal combineLatest:@[currentFolder, RACAble(self.selectedFolder), RACAble(self.excludeDirectory), tableView] reduce:^(RCIODirectory *c, RCIODirectory *s, RCIODirectory *e, id _) {
		return @(s ? s != e : c != e);
	}] replayLast];
	[shouldEnableSignal toProperty:@keypath(self.navigationItem.rightBarButtonItem.enabled) onObject:self];
	[shouldEnableSignal toProperty:@keypath(self.hideExcludeMessage) onObject:self];
	
  // Update table content
  [[[[[currentFolder map:^(RCIODirectory *x) {
    return x.childrenSignal;
  }] switchToLatest] map:^(NSArray *children) {
		NSMutableArray *subfolders = [NSMutableArray arrayWithCapacity:children.count];
		for (RCIOItem *item in children) {
			if ([item isKindOfClass:RCIODirectory.class]) [subfolders addObject:item];
		}
		return subfolders;
	}] catchTo:RACSignal.empty] toProperty:@keypath(self.currentFolderSubfolders) onObject:self];
  
  // Update title
  [[[[RACAble(self.currentFolderSignal) switchToLatest] flattenMap:^(RCIODirectory *x) {
    return x.nameSignal;
  }] catchTo:RACSignal.empty] toProperty:@keypath(self.navigationItem.title) onObject:self];
  
  // reload table
  [[RACSignal combineLatest:@[RACAble(self.currentFolderSubfolders), tableView] reduce:^(NSArray *_, UITableView *x) {
		return x;
	}] subscribeNext:^(UITableView *x) {
    [x reloadData];
  }];
  
  return self;
}

- (void)setHideExcludeMessage:(BOOL)hideExcludeMessage {
	_hideExcludeMessage = hideExcludeMessage;
	
	if (!hideExcludeMessage) {
		UILabel *excludeLabel = [[UILabel alloc] init];
		excludeLabel.text = L(@"The file is in this directory");
		excludeLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		excludeLabel.textAlignment = NSTextAlignmentCenter;
		excludeLabel.backgroundColor = UIColor.lightGrayColor;
		excludeLabel.textColor = UIColor.whiteColor;
		[excludeLabel sizeToFit];
		self.tableView.tableHeaderView = excludeLabel;
	} else {
		self.tableView.tableHeaderView = nil;
	}
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.selectedFolder = nil;
}

#pragma mark - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.currentFolderSubfolders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  RCIOItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[RCIOItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  
  cell.item = (self.currentFolderSubfolders)[indexPath.row];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  
  return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedFolder = (self.currentFolderSubfolders)[indexPath.row];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  ASSERT(self.navigationController != nil);
  
  FolderBrowserController *nextBrowser = [[FolderBrowserController alloc] initWithStyle:self.tableView.style];
  nextBrowser.currentFolderSignal = [RACSignal return:(self.currentFolderSubfolders)[indexPath.row]];
  nextBrowser.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
	nextBrowser.excludeDirectory = self.excludeDirectory;
  [self.navigationController pushViewController:nextBrowser animated:YES];
}

@end

