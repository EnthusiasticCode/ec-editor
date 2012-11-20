//
//  DirectoryBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FolderBrowserController.h"
#import "UIImage+AppStyle.h"
#import "ArtCodeTab.h"
#import "NSString+PluralFormat.h"
#import "FileSystemItem.h"
#import "FileSystemItemCell.h"


@interface FolderBrowserController ()

@property (nonatomic, strong) FileSystemDirectory *selectedFolder;
@property (nonatomic, strong) NSArray *currentFolderSubfolders;

@end

#pragma mark

@implementation FolderBrowserController

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  
  // RAC
  
  // Update table content
  [[[[[[RACAble(self.currentFolderSubscribable) switch] map:^id<RACSubscribable>(FileSystemDirectory *folder) {
    return [folder children];
  }] switch] map:^id<RACSubscribable>(NSArray *children) {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
      NSMutableArray *childFolders = [[NSMutableArray alloc] init];
      return [[[[[children rac_toSubscribable] flattenMap:^id<RACSubscribable>(FileSystemItem *x) {
        return [RACSubscribable combineLatest:@[[RACSubscribable return:x], [x.type take:1]]];
      }] filter:^BOOL(RACTuple *xs) {
        return xs.second == NSURLFileResourceTypeDirectory;
      }] map:^id(RACTuple *xs) {
        return xs.first;
      }] subscribeNext:^(FileSystemItem *x) {
        [childFolders addObject:x];
      } error:^(NSError *error) {
        [subscriber sendError:error];
      } completed:^{
        [subscriber sendNext:childFolders];
        [subscriber sendCompleted];
      }];
    }];
  }] switch] toProperty:@keypath(self.currentFolderSubfolders) onObject:self];
  
  // Update title
  [[[[RACAble(self.currentFolderSubscribable) switch] map:^id<RACSubscribable>(FileSystemDirectory *folder) {
    return [folder name];
  }] switch] toProperty:@keypath(self.navigationItem.title) onObject:self];
  
  // reload table
  [[RACSubscribable combineLatest:@[RACAble(self.currentFolderSubfolders), RACAbleWithStart(self.tableView)]] subscribeNext:^(RACTuple *xs) {
    [xs.second reloadData];
  }];
  
  return self;
}

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.currentFolderSubfolders.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  FileSystemItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[FileSystemItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  
  cell.item = [self.currentFolderSubfolders objectAtIndex:indexPath.row];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  
  return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.selectedFolder = [self.currentFolderSubfolders objectAtIndex:indexPath.row];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  ASSERT(self.navigationController != nil);
  
  FolderBrowserController *nextBrowser = [[FolderBrowserController alloc] initWithStyle:self.tableView.style];
  nextBrowser.currentFolderSubscribable = [RACSubscribable return:[self.currentFolderSubfolders objectAtIndex:indexPath.row]];
  nextBrowser.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
  [self.navigationController pushViewController:nextBrowser animated:YES];
}

@end

