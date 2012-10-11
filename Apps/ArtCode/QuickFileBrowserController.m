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
  @weakify(self);
  [[[[[RACAble(self.artCodeTab.currentLocation.project.fileURL) select:^id<RACSubscribable>(NSURL *projectURL) {
    return [FileSystemItem directoryWithURL:projectURL];
  }] switch] select:^id<RACSubscribable>(FileSystemItem *directory) {
    @strongify(self);
    if (!self) { return nil; }
    return [directory childrenWithOptions:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsPackageDescendants filteredByAbbreviation:self.searchBarTextSubject];
  }] switch] toProperty:RAC_KEYPATH_SELF(filteredItems) onObject:self];
  
  [RACAble(self.filteredItems) subscribeNext:^(NSArray *items) {
    @strongify(self);
    if (!self) { return; }
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

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  RACTuple *item = [self.filteredItems objectAtIndex:indexPath.row];
  NSURL *itemURL = item.first;
  if (itemURL.isDirectory)
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  else
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemURL.pathExtension];
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = item.second;
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
