//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "FileSystemItem.h"
#import "NSTimer+BlockTimer.h"
#import "NSString+Utilities.h"
#import "NSURL+Utilities.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"

#import "ArtCodeProjectSet.h"
#import "ArtCodeProject.h"

#import "AppStyle.h"
#import "FileSystemItemCell.h"


@interface QuickFileBrowserController ()

@property (nonatomic, copy) NSArray *filteredItems;

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController

#pragma mark - Controller lifecycle

- (id)init
{
  self = [super initWithTitle:L(@"Open quickly") searchBarStaticOnTop:YES];
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
  [[[[[RACAble(self.artCodeTab.currentLocation.project.fileURL) map:^id<RACSubscribable>(NSURL *projectURL) {
    return [FileSystemDirectory directoryWithURL:projectURL];
  }] switch] map:^id<RACSubscribable>(FileSystemDirectory *directory) {
    @strongify(self);
    return [directory childrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles filteredByAbbreviation:self.searchBarTextSubject];
  }] switch] toProperty:@keypath(self.filteredItems) onObject:self];
  
  [RACAble(self.filteredItems) subscribeNext:^(NSArray *items) {
    @strongify(self);
    if (items.count == 0) {
      self.infoLabel.text = L(@"Nothing found.");
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
  
  FileSystemItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[FileSystemItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    cell.textLabel.backgroundColor = [UIColor clearColor];
  }
  
  // Configure the cell
  RACTuple *filteredItem = [self.filteredItems objectAtIndex:indexPath.row];
  FileSystemItem *item = filteredItem.first;
  NSIndexSet *hitMask = filteredItem.second;
  cell.item = item;
  cell.hitMask = hitMask;
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  FileSystemItem *item = [[self.filteredItems objectAtIndex:indexPath.row] first];
  [[[item url] take:1] subscribeNext:^(NSURL *x) {
    [self.artCodeTab pushFileURL:x withProject:self.artCodeTab.currentLocation.project];
  }];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushProject:self.artCodeTab.currentLocation.project];
}

- (void)_showProjectsInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushDefaultProjectSet];
}

@end
