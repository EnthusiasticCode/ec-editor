//
//  QuickFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickFileBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "NSTimer+BlockTimer.h"
#import "NSArray+ScoreForAbbreviation.h"

#import "ArtCodeURL.h"
#import "ArtCodeTab.h"

#import "ACProject.h"

#import "AppStyle.h"
#import "HighlightTableViewCell.h"


@interface QuickFileBrowserController ()

- (void)_showBrowserInTabAction:(id)sender;
- (void)_showProjectsInTabAction:(id)sender;

@end


@implementation QuickFileBrowserController {
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;
}

#pragma mark - Properties

- (NSArray *)filteredItems
{
  if (!_filteredItems)
  {
    if ([self.searchBar.text length])
    {
      NSArray *hitMasks = nil;
      _filteredItems = [self.artCodeTab.currentProject.allFiles sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(NSURL *elementURL) {
        return elementURL.lastPathComponent;
      }];
      _filteredItemsHitMasks = hitMasks;
      if ([_filteredItems count] == 0)
        self.infoLabel.text = L(@"Nothing found.");
      else
        self.infoLabel.text = @"";
    }
    else
    {
      _filteredItems = nil;
      _filteredItemsHitMasks = nil;
      self.infoLabel.text = L(@"Type a file name to open.");
    }
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems
{
  _filteredItems = nil;
  _filteredItemsHitMasks = nil;
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
  if (itemURL.isArtCodeDirectory)
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  else
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:itemURL.pathExtension];
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = _filteredItemsHitMasks ? [_filteredItemsHitMasks objectAtIndex:indexPath.row] : nil;
  cell.detailTextLabel.text = itemURL.prettyPath;
  
  return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushURL:[[self.filteredItems objectAtIndex:indexPath.row] artCodeURL]];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushURL:[self.artCodeTab.currentProject artCodeURL]];
}

- (void)_showProjectsInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushURL:[ArtCodeURL artCodeURLWithProject:nil type:ArtCodeURLTypeProjectsList path:nil]];
}

@end
