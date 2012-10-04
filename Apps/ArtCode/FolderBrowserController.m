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
#import "FileSystemDirectory.h"

@interface FolderBrowserController ()

@property (nonatomic, strong, readonly) NSArray *currentFolderSubfolders;

@end

#pragma mark

@implementation FolderBrowserController

@synthesize currentFolderURL = _currentFolderURL, currentFolderSubfolders = _currentFolderSubfolders;

- (void)setCurrentFolderURL:(NSURL *)currentFolderURL {
  if (currentFolderURL == _currentFolderURL)
    return;
  
  _currentFolderURL = currentFolderURL;
  self.navigationItem.title = currentFolderURL.lastPathComponent;
  _currentFolderSubfolders = nil;
  [self.tableView reloadData];
}

- (NSArray *)currentFolderSubfolders {
  if (!_currentFolderSubfolders) {
    NSMutableArray *result = [NSMutableArray new];
    NSNumber *isDirectory;
    for (NSURL *subfolderURL in [[NSFileManager defaultManager] enumeratorAtURL:self.currentFolderURL includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLIsDirectoryKey, nil] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:NULL]) {
      [subfolderURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
      if ([isDirectory boolValue]) {
        [result addObject:subfolderURL];
      }
    }
    _currentFolderSubfolders = [result copy];
  }
  return _currentFolderSubfolders;
}

- (NSURL *)selectedFolderURL {
  if (self.tableView.indexPathForSelectedRow)
    return [self.currentFolderSubfolders objectAtIndex:self.tableView.indexPathForSelectedRow.row];
  return self.currentFolderURL;
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
  
  NSURL *itemURL = [self.currentFolderSubfolders objectAtIndex:indexPath.row];
  cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  cell.textLabel.text = itemURL.lastPathComponent;
  
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  ASSERT(self.navigationController != nil);
  
  FolderBrowserController *nextBrowser = [[FolderBrowserController alloc] initWithStyle:self.tableView.style];
  nextBrowser.currentFolderURL = [self.currentFolderSubfolders objectAtIndex:indexPath.row];
  nextBrowser.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
  [self.navigationController pushViewController:nextBrowser animated:YES];
}

@end

