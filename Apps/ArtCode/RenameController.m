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
  // TODO hide or show additionals
  self.alsoRenameTableView.hidden = YES;
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


@end
