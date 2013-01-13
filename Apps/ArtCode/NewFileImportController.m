//
//  NewFileImportController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/11/12.
//
//

#import "NewFileImportController.h"
#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "FileSystemDirectory.h"
#import "NSURL+Utilities.h"
#import "ArchiveUtilities.h"
#import "UIImage+AppStyle.h"
#import "MoveConflictController.h"
#import "BezelAlert.h"
#import "UIViewController+Utilities.h"

@interface NewFileImportController ()
// Items shown in the table view that could be imported
@property (nonatomic, strong) NSArray *importableFileItems;

// Return a list of NSURLs of non archive files in the document directory
- (NSArray *)_importableFileURLsInDocuments;
@end

@implementation NewFileImportController

static void _init(NewFileImportController *self) {
  @weakify(self);

  // Reaction to update table data
  [RACAble(self.importableFileItems) subscribeNext:^(id x) {
    @strongify(self);
    [self.tableView reloadData];
  }];
}

- (id)initWithStyle:(UITableViewStyle)style {
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  _init(self);
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self) {
    return nil;
  }
  _init(self);
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  self.importableFileItems = [self _importableFileURLsInDocuments];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  _importableFileItems = nil;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.importableFileItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"DefaultCell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  NSURL *fileURL = self.importableFileItems[indexPath.row];
  cell.textLabel.text = fileURL.lastPathComponent;
  cell.imageView.image = fileURL.isDirectory ? [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)] : [UIImage styleDocumentImageWithFileExtension:fileURL.pathExtension];
    
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    [NSFileManager.defaultManager removeItemAtURL:self.importableFileItems[indexPath.row] error:NULL];
    _importableFileItems = [self _importableFileURLsInDocuments];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  self.navigationItem.rightBarButtonItem.enabled = tableView.indexPathsForSelectedRows.count > 0;
}

#pragma mark - Public methods

- (IBAction)importAction:(id)sender {
  [sender setEnabled:NO];
  
  // Get items to import
  @weakify(self);
  [[RACSignal zip:@[
  [RACSignal zip:[self.tableView.indexPathsForSelectedRows.rac_sequence.eagerSequence map:^RACSignal *(NSIndexPath *x) {
    @strongify(self);
    return [FileSystemItem itemWithURL:self.importableFileItems[x.row]];
  }]],
  [FileSystemDirectory itemWithURL:self.parentViewController.artCodeTab.currentLocation.url] ]] subscribeNext:^(RACTuple *x) {
    @strongify(self);
    NSArray *items = [x.first allObjects];
    FileSystemDirectory *copyToDirectory = x.second;
    
    // Dismiss popover
    [self.navigationController.presentingPopoverController dismissPopoverAnimated:YES];
    
    // Initialize and present conflict controller
    MoveConflictController *conflictController = [[MoveConflictController alloc] init];
    UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(dismissModalViewControllerAnimated:)];
    [cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    conflictController.navigationItem.leftBarButtonItem = cancelItem;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:conflictController];
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navigationController animated:YES completion:^{
      // Start copy
			__block NSUInteger importedCount = 0;
      [[[conflictController moveItems:items toFolder:copyToDirectory usingSignalBlock:^RACSignal *(FileSystemItem *item, FileSystemDirectory *destinationFolder) {
				importedCount++;
        return [item copyTo:destinationFolder];
      }] finally:^{
        ASSERT_MAIN_QUEUE();
        [self dismissViewControllerAnimated:YES completion:nil];
      }] subscribeError:^(NSError *error) {
        ASSERT_MAIN_QUEUE();
        [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Error importing files") imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
      } completed:^{
        ASSERT_MAIN_QUEUE();
        if (importedCount > 0) {
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Files imported") imageNamed:BezelAlertOkIcon displayImmediatly:NO];
        }
      }];
    }];
  }];
}

#pragma mark - Private Methods

- (NSArray *)_importableFileURLsInDocuments {
  NSMutableArray *result = [[NSMutableArray alloc] init];
  for (NSURL *url in [NSFileManager.defaultManager enumeratorAtURL:[NSURL applicationDocumentsDirectory] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants errorHandler:nil]) {
    if (![url isArchiveURL]) {
      [result addObject:url];
    }
  }
  
  // Side effect to update hint label
  if (result.count != 0) {
    [(UILabel *)self.tableView.tableFooterView setText:L(@"Swipe on an item to delete it.")];
  } else {
    [(UILabel *)self.tableView.tableFooterView setText:L(@"Add files from iTunes to populate this list.")];
  }
  
  return [result copy];
}

@end
