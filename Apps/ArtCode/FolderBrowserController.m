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
  [[[[[RACAble(self.currentFolderSignal) switch] flattenMap:^(FileSystemDirectory *x) {
    return x.children;
  }] map:^(NSArray *x) {
		return [[RACSignal merge:[x map:^(FileSystemItem *y) {
			return [[[y.type take:1] filter:^ BOOL (NSString *z) {
				return z == NSURLFileResourceTypeDirectory;
			}] mapReplace:y];
		}]] collect];
  }] switch] toProperty:@keypath(self.currentFolderSubfolders) onObject:self];
  
  // Update title
  [[[RACAble(self.currentFolderSignal) switch] flattenMap:^(FileSystemDirectory *x) {
    return x.name;
  }] toProperty:@keypath(self.navigationItem.title) onObject:self];
  
  // reload table
  [[RACSignal combineLatest:@[RACAble(self.currentFolderSubfolders), RACAbleWithStart(self.tableView)] reduce:^(NSArray *_, UITableView *x) {
		return x;
	}] subscribeNext:^(UITableView *x) {
    [x reloadData];
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
  [self.navigationController pushViewController:nextBrowser animated:YES];
}

@end

