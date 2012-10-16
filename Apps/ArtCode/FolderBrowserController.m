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
  [[[[[RACAble(self.currentFolderSubscribable) switch] select:^id<RACSubscribable>(FileSystemDirectory *folder) {
    return [folder children];
  }] switch] select:^NSArray *(NSArray *children) {
    return [[[children rac_toSubscribable] where:^BOOL(FileSystemItem *child) {
      return child.type.first == NSURLFileResourceTypeDirectory;
    }] toArray];
  }] toProperty:RAC_KEYPATH_SELF(self.currentFolderSubfolders) onObject:self];
  
  // Update title
  [[[[RACAble(self.currentFolderSubscribable) switch] select:^id<RACSubscribable>(FileSystemDirectory *folder) {
    return [folder name];
  }] switch] toProperty:RAC_KEYPATH_SELF(self.navigationItem.title) onObject:self];
  
  // reload table
  [[RACSubscribable combineLatest:@[RACAble(self.currentFolderSubfolders), RACAble(self.tableView)]] subscribeNext:^(RACTuple *xs) {
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
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  }
  
  FileSystemDirectory *subfolder = [self.currentFolderSubfolders objectAtIndex:indexPath.row];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  cell.textLabel.text = subfolder.name.first;
  
  // TODO add child descriptions (number of files, folders)
//  cell.detailTextLabel.text = [item childrenDescription];
//  // Generate string if empty
//  if (fileCount == 0 && subDirectoryCount == 0)
//    return @"Empty";
//  
//  // Generate string with plural form
//  NSString *result = fileCount ? [NSString stringWithFormatForSingular:@"%u file" plural:@"%u files" count:fileCount] : nil;
//  if (subDirectoryCount)
//    result = result ? [result stringByAppendingFormatForSingular:@", %u folder" plural:@", %u folders" count:subDirectoryCount] : [NSString stringWithFormatForSingular:@"%u folder" plural:@"%u folders" count:subDirectoryCount];
//  return result;
  
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

