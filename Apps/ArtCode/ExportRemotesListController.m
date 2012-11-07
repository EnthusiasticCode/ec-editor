//
//  ExportRemotesListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExportRemotesListController.h"
#import "ArtCodeRemote.h"

@implementation ExportRemotesListController

@synthesize remotes, remoteSelectedBlock;

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return YES;
}

#pragma mark - UITableView data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.remotes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  ArtCodeRemote *remote = [self.remotes objectAtIndex:indexPath.row];
  cell.textLabel.text = remote.name;
  cell.detailTextLabel.text = remote.url.absoluteString;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  
  return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.remoteSelectedBlock) {
    self.remoteSelectedBlock(self, [self.remotes objectAtIndex:indexPath.row]);
  }
}

@end
