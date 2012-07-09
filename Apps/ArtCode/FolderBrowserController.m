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
#import "ACProject.h"
#import "NSString+PluralFormat.h"


// Category that implements utility methods to divide the children between files 
// and folders.
@interface ACProjectFolder (ChildrenInfo)

- (NSArray *)childFolders;

// Returns a presentable string of the number of folders and files in this item. 
- (NSString *)childrenDescription;

@end

#pragma mark -

@implementation FolderBrowserController

@synthesize currentFolder = _currentFolder;

#pragma mark - UIViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - UITableView Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self.currentFolder.childFolders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  }
  
  ACProjectFolder *item = [self.currentFolder.childFolders objectAtIndex:indexPath.row];
  cell.accessoryType = [item.childFolders count] ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
  cell.textLabel.text = item.name;
  cell.detailTextLabel.text = [item childrenDescription];
  
  return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  ASSERT(self.navigationController != nil);
  
  FolderBrowserController *nextBrowser = [[FolderBrowserController alloc] initWithStyle:self.tableView.style];
  nextBrowser.currentFolder = [self.currentFolder.childFolders objectAtIndex:indexPath.row];
  nextBrowser.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
  [self.navigationController pushViewController:nextBrowser animated:YES];
}

#pragma mark - Public Methods

- (void)setCurrentFolder:(ACProjectFolder *)value {
  if (value == _currentFolder)
    return;
  
  _currentFolder = value;
  [self.tableView reloadData];
}

- (ACProjectFolder *)selectedFolder {
  if (self.tableView.indexPathForSelectedRow)
    return [self.currentFolder.childFolders objectAtIndex:self.tableView.indexPathForSelectedRow.row];
  return self.currentFolder;
}

@end

#pragma mark -

@implementation ACProjectFolder (ChildrenInfo)

- (NSArray *)childFolders {
  NSMutableArray *childFolders = [[NSMutableArray alloc] init];
  for (ACProjectFileSystemItem *item in self.children) {
    if (item.type == ACPFolder)
      [childFolders addObject:item];
  }
  return [childFolders copy];
}

- (NSString *)childrenDescription
{
  // Calculate number of subitems
  NSInteger subDirectoryCount = 0;
  NSInteger fileCount = 0;
  for (ACProjectFileSystemItem *item in self.children) {
    if (item.type == ACPFolder) {
      ++subDirectoryCount;
    } else {
      ++fileCount;
    }
  }
  
  // Generate string if empty
  if (fileCount == 0 && subDirectoryCount == 0)
    return @"Empty";
  
  // Generate string with plural form
  NSString *result = fileCount ? [NSString stringWithFormatForSingular:@"%u file" plural:@"%u files" count:fileCount] : nil;
  if (subDirectoryCount)
    result = result ? [result stringByAppendingFormatForSingular:@", %u folder" plural:@", %u folders" count:subDirectoryCount] : [NSString stringWithFormatForSingular:@"%u folder" plural:@"%u folders" count:subDirectoryCount];
  return result;
}

@end
