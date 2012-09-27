//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "FileSystemDirectory+FilterByAbbreviation.h"
#import "RACTableViewDataSource.h"
#import "NSTimer+BlockTimer.h"
#import "NSString+Utilities.h"
#import "NSURL+Utilities.h"

#import "ArtCodeLocation.h"
#import "ArtCodeTab.h"

#import "ArtCodeProjectSet.h"
#import "ArtCodeProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"


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
  __weak QuickFileBrowserController *weakSelf = self;
  [[FileSystemDirectory readItemAtURL:self.artCodeTab.currentLocation.project.fileURL] subscribeNext:^(FileSystemDirectory *directory) {
    QuickFileBrowserController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    RACTableViewDataSource *dataSource = [[RACTableViewDataSource alloc] initWithSubscribable:[directory contentWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants filteredByAbbreviation:strongSelf.searchBarTextSubject]];
    [RACAble(dataSource, items) toProperty:RAC_KEYPATH(strongSelf, filteredItems) onObject:strongSelf];
  }];
  [RACAbleSelf(filteredItems) subscribeNext:^(NSArray *items) {
    QuickFileBrowserController *strongSelf = weakSelf;
    if (!strongSelf) {
      return;
    }
    if (items.count == 0) {
      strongSelf.infoLabel.text = L(@"Nothing found.");
    } else {
      strongSelf.infoLabel.text = @"";
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

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  NSURL *itemURL = [self.filteredItems objectAtIndex:indexPath.row];
  if (itemURL.isDirectory)
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  else
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemURL.pathExtension];
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = [itemURL abbreviationHitMask];
  cell.detailTextLabel.text = [[ArtCodeProjectSet defaultSet] relativePathForFileURL:itemURL].prettyPath;
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushFileURL:[self.filteredItems objectAtIndex:indexPath.row] withProject:self.artCodeTab.currentLocation.project];
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
