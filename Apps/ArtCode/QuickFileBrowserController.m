//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import <ReactiveCocoaIO/ReactiveCocoaIO.h>
#import "NSTimer+BlockTimer.h"
#import "NSString+Utilities.h"
#import "RACSignal+ScoreForAbbreviation.h"
#import "NSURL+Utilities.h"
#import "NSURL+ArtCode.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"

#import "AppStyle.h"
#import "RCIOItemCell.h"


@interface QuickFileBrowserController ()

@property (nonatomic, copy) NSArray *filteredItems;

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController

#pragma mark - Controller lifecycle

- (id)init
{
  self = [super initWithNibNamed:nil title:L(@"Open quickly") searchBarStaticOnTop:YES];
  if (!self)
    return nil;
  float iconSize = 26;
  self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:[UIImage styleDocumentImageWithSize:CGSizeMake(iconSize, iconSize) color:[UIColor whiteColor] text:nil] tag:0];
  self.navigationItem.title = L(@"Open quickly");
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Show") style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
  UIBarButtonItem *backToProjectsItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Projects") style:UIBarButtonItemStylePlain target:self action:@selector(_showProjectsInTabAction:)];
  [backToProjectsItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  self.navigationItem.leftBarButtonItem = backToProjectsItem;
  
  // RAC
  @weakify(self);
  [[[[[[RACAble(self.artCodeTab.currentLocation.url.projectRootDirectory) map:^RACSignal *(NSURL *projectURL) {
    return [RCIODirectory itemWithURL:projectURL];
  }] switchToLatest] map:^RACSignal *(RCIODirectory *directory) {
		ASSERT_MAIN_QUEUE();
    @strongify(self);
		return [[[directory childrenSignalWithOptions:NSDirectoryEnumerationSkipsHiddenFiles] filterArraySignalByAbbreviation:self.searchBarTextSubject extrapolateTargetStringBlock:^(RCIOItem *item) {
			return item.url.lastPathComponent;
		}] map:^(NSArray *items) {
			@strongify(self);
			if (self.searchBar.text.length == 0) return @[];
			return items;
		}];
  }] switchToLatest] catchTo:RACSignal.empty] toProperty:@keypath(self.filteredItems) onObject:self];
  
  [[RACSignal combineLatest:@[ RACAble(self.filteredItems), self.searchBarTextSubject ]] subscribeNext:^(RACTuple *value) {
		ASSERT_MAIN_QUEUE();
    @strongify(self);
		RACTupleUnpack(NSArray *items, NSString *abbreviation) = value;
    if (items.count == 0) {
			if (abbreviation.length == 0) {
				self.infoLabel.text = L(@"Type a file name to open.");
			} else {
				self.infoLabel.text = L(@"Nothing found.");
			}
    } else {
      self.infoLabel.text = @"";
    }
  }];
	
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  return [self init];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.searchBar.placeholder = L(@"Search for file");
	self.infoLabel.text = L(@"Type a file name to open.");
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [self.searchBar becomeFirstResponder];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"Cell";
  
  RCIOItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[RCIOItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    cell.textLabel.backgroundColor = [UIColor clearColor];
  }
  
  // Configure the cell
  RACTuple *filteredItem = (self.filteredItems)[indexPath.row];
  RCIOItem *item = filteredItem.first;
  NSIndexSet *hitMask = filteredItem.second;
  cell.item = item;
  cell.textLabelHighlightedCharacters = hitMask;
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  RCIOItem *item = [(self.filteredItems)[indexPath.row] first];
	[self.artCodeTab pushFileURL:item.url];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushFileURL:self.artCodeTab.currentLocation.url.projectRootDirectory];
}

- (void)_showProjectsInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushProjectsList];
}

@end
