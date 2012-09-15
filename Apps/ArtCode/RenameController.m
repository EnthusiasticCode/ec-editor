//
//  RenameController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/08/12.
//
//

#import "RenameController.h"


@implementation RenameController {
  NSURL *_fileURL;
  void (^_completionHandler)(NSUInteger renamedCount, NSError *err);
  
  NSArray *_alsoRenameURLs;
}

#pragma mark - Controller lifecycle

- (id)initWithRenameItemAtURL:(NSURL *)fileURL completionHandler:(void (^)(NSUInteger, NSError *))completionHandler {
  self = [super initWithNibName:@"RenameModalView" bundle:nil];
  if (!self) {
    return nil;
  }
  
  // The right button in a navigation controller will perform the operation
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Rename") style:UIBarButtonItemStyleDone target:self action:@selector(_doneAction:)];
  
  // Prepare for rename
  _fileURL = fileURL;
  _completionHandler = completionHandler;
  
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  ASSERT(NO); // Use init
  return nil;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  self.originalNameLabel.text = self.renameTextField.text = _fileURL.lastPathComponent;
  [self _updateAlsoRenameTableForFileWithURL:_fileURL];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _alsoRenameURLs.count;
}

#pragma mark - UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"default";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
  }
  
  cell.textLabel.text = [[_alsoRenameURLs objectAtIndex:indexPath.row] lastPathComponent];
  // TODO add file icon
  
  return cell;
}

#pragma mark - Private methods

- (void)_doneAction:(id)sender {
  NSFileCoordinator *fileCoordinator = [NSFileCoordinator new];
  NSFileManager *fileManager = [NSFileManager new];
  // Rename original file
  __block NSError *err = nil;
  __block NSUInteger count = 0;
  NSURL *destinationURL = [_fileURL URLByDeletingLastPathComponent];
  [fileCoordinator coordinateReadingItemAtURL:_fileURL options:0 writingItemAtURL:[destinationURL URLByAppendingPathComponent:self.renameTextField.text] options:0 error:&err byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
    [fileManager moveItemAtURL:newReadingURL toURL:newWritingURL error:&err];
    if (!err) {
      count++;
    }
  }];
  // Rename related files
  // TODO
  // Return to continuation
  if (_completionHandler) {
    _completionHandler(count, err);
  }
}

- (void)_updateAlsoRenameTableForFileWithURL:(NSURL *)fileURL {
  NSMutableArray *alsoRename = [NSMutableArray new];
  [[NSFileCoordinator new] coordinateReadingItemAtURL:fileURL.URLByDeletingLastPathComponent options:0 error:NULL byAccessor:^(NSURL *newURL) {
    // Get the name of the file to find similar files
    NSString *fileName = fileURL.lastPathComponent.stringByDeletingPathExtension;
    // Enumerate all files in the original file directory
    for (NSURL *otherFileURL in [[NSFileManager new] enumeratorAtURL:newURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:NULL]) {
      // Skip renamed file
      if ([otherFileURL isEqual:fileURL])
        continue;
      // Check for match
      if ([otherFileURL.lastPathComponent hasPrefix:fileName]) {
        [alsoRename addObject:otherFileURL];
      }
    }
  }];
  _alsoRenameURLs = [alsoRename copy];
  // Hide or show 'also rename' table view if needed
  if (_alsoRenameURLs.count) {
    self.alsoRenameView.hidden = NO;
    self.alsoRenameTableView.editing = YES;
    [self.alsoRenameTableView reloadData];
  } else {
    self.alsoRenameView.hidden = YES;
  }
}

@end
