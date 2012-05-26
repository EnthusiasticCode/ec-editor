//
//  QuickBookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickBookmarkBrowserController.h"
#import "QuickBrowsersContainerController.h"

#import "ArtCodeTab.h"
#import "ArtCodeURL.h"

#import "ACProject.h"


@interface QuickBookmarkBrowserController (/*Private methods*/)

- (void)_showBrowserInTabAction:(id)sender;

@end

@implementation QuickBookmarkBrowserController

- (id)init
{
  self = [super init];
  if (!self)
    return nil;
  self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Bookmarks" image:[UIImage imageNamed:@"UITabBar_star"] tag:0];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleDone target:self action:@selector(_showBrowserInTabAction:)];
  self.navigationItem.title = @"Bookmarks";
  return self;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [super tableView:table didSelectRowAtIndexPath:indexPath];
}

#pragma mark - Private methods

- (void)_showBrowserInTabAction:(id)sender
{
  [self.quickBrowsersContainerController.presentingPopoverController dismissPopoverAnimated:YES];
  [self.artCodeTab pushURL:[ArtCodeURL artCodeURLWithProject:self.artCodeTab.currentProject item:nil path:artCodeURLProjectBookmarkListPath]];
}

@end
