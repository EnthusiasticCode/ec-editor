//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "SmartFilteredDirectoryPresenter.h"
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

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController {
  SmartFilteredDirectoryPresenter *_filteredDirectoryPresenter;
}

#pragma mark - Properties

- (NSArray *)filteredItems {
  if (!_filteredDirectoryPresenter) {
    _filteredDirectoryPresenter = [[SmartFilteredDirectoryPresenter alloc] initWithDirectoryURL:self.artCodeTab.currentLocation.project.fileURL options:0];
  }
  
  _filteredDirectoryPresenter.filterString = self.searchBar.text;
  
  if (self.searchBar.text.length == 0) {
    self.infoLabel.text = L(@"Type a file name to open.");
  } else if (_filteredDirectoryPresenter.fileURLs.count == 0) {
    self.infoLabel.text = L(@"Nothing found.");
  } else {
    self.infoLabel.text = @"";
  }
  return _filteredDirectoryPresenter.fileURLs;
}

- (void)invalidateFilteredItems {
  _filteredDirectoryPresenter = nil;
}

#pragma mark - Controller lifecycle

- (id)init
{
  self = [super initWithTitle:L(@"Open quickly") searchBarStaticOnTop:YES];
  if (!self)
    return nil;
  float iconSize = UIScreen.mainScreen.scale * 26;
  self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Files" image:[UIImage styleDocumentImageWithSize:CGSizeMake(iconSize, iconSize) color:[UIColor whiteColor] text:nil] tag:0];
  self.navigationItem.title = L(@"Open quickly");
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Show") style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
  UIBarButtonItem *backToProjectsItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Projects") style:UIBarButtonItemStylePlain target:self action:@selector(_showProjectsInTabAction:)];
  [backToProjectsItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  self.navigationItem.leftBarButtonItem = backToProjectsItem;
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

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:table cellForRowAtIndexPath:indexPath];
  
  NSURL *itemURL = [self.filteredItems objectAtIndex:indexPath.row];
  if (itemURL.isDirectory)
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  else
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemURL.pathExtension];
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = [_filteredDirectoryPresenter hitMaskForFileURL:itemURL];
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
