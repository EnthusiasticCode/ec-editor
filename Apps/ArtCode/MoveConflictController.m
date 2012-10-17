//
//  MoveConflictController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoveConflictController.h"
#import "NSURL+Utilities.h"
#import "ArtCodeProject.h"
#import "UIImage+AppStyle.h"
#import "FileSystemItem.h"


@implementation MoveConflictController {
  NSMutableArray *_resolvedItems;
  NSMutableArray *_conflictItems;
  void (^_processingBlock)(FileSystemItem *);
  void (^_completionBlock)(void);
}

@synthesize toolbar;
@synthesize conflictTableView;
@synthesize progressView;

#pragma mark - Object

- (id)init {
  self = [super initWithNibName:@"MoveConflictController" bundle:nil];
  if (!self)
    return nil;
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
  return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  return [self init];
}

#pragma mark - UIViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [[self.toolbar.items objectAtIndex:0] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  [[self.toolbar.items objectAtIndex:1] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)viewDidUnload {
  [self setConflictTableView:nil];
  [self setProgressView:nil];
  [self setToolbar:nil];
  _conflictItems = nil;
  _resolvedItems = nil;
  _processingBlock = nil;
  _completionBlock = nil;
  [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_conflictItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const cellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  FileSystemItem *item = [_conflictItems objectAtIndex:indexPath.row];
  cell.textLabel.text = item.name.first;
  if (item.type.first == NSURLFileResourceTypeDirectory)
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  else
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[item.name.first pathExtension]];
  cell.detailTextLabel.text = [item.url.first prettyPath];
  
  return cell;
}

#pragma mark - Public Methods

- (void)moveItems:(NSArray *)items toFolder:(FileSystemDirectory *)destinationFolder usingBlock:(void (^)(FileSystemItem *))processingBlock completion:(void (^)(void))completionBlock {
  _conflictItems = [[NSMutableArray alloc] init];
  _resolvedItems = [NSMutableArray arrayWithArray:items];
  _processingBlock = [processingBlock copy];
  _completionBlock = [completionBlock copy];
  
  // Processing
  @weakify(self);
  [[[destinationFolder children] selectMany:^id<RACSubscribable>(FileSystemItem *x) {
    return [x.name take:1];
  }] subscribeNext:^(NSString *x) {
    @strongify(self);
    if (!self) {
      return;
    }
    FileSystemItem *conflict = nil;
    for (FileSystemItem *item in self->_resolvedItems) {
      if ([item.name.first isEqual:x]) {
        conflict = item;
        break;
      }
    }
    if (conflict) {
      [self->_resolvedItems removeObject:conflict];
      [self->_conflictItems addObject:conflict];
    }
  } completed:^{
    @strongify(self);
    // If there are no conflict items we are done
    if ([self->_conflictItems count] == 0) {
      [self doneAction:nil];
      return;
    }
    
    // Prepare to show conflict resolution UI
    self.conflictTableView.hidden = NO;
    self.toolbar.hidden = NO;
    self.progressView.hidden = YES;
    [self.conflictTableView reloadData];
    [self.conflictTableView setEditing:YES animated:NO];
    self.navigationItem.title = @"Select files to replace";
  }];
}

#pragma mark - Interface Actions and Outlets

- (IBAction)doneAction:(id)sender {
  // Show progress UI
  self.conflictTableView.hidden = YES;
  self.toolbar.hidden = YES;
  self.progressView.hidden = NO;
  self.progressView.progress = 0;
  self.navigationItem.title = @"Replacing";
  
  // Adding selected items to list of resolved and removing from conflict table
  NSMutableIndexSet *selectedIndexSet = [[NSMutableIndexSet alloc] init];
  for (NSIndexPath *selectedIndexPath in [self.conflictTableView indexPathsForSelectedRows]) {
    [selectedIndexSet addIndex:selectedIndexPath.row];
  }
  [_resolvedItems addObjectsFromArray:[_conflictItems objectsAtIndexes:selectedIndexSet]];
  [_conflictItems removeObjectsAtIndexes:selectedIndexSet];
  [self.conflictTableView deleteRowsAtIndexPaths:[self.conflictTableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationAutomatic];
  
  // Processing
  ASSERT(_processingBlock);
  float resolvedCount = [_resolvedItems count];
  [_resolvedItems enumerateObjectsUsingBlock:^(FileSystemItem *item, NSUInteger idx, BOOL *stop) {
    _processingBlock(item);
    self.progressView.progress = (float)(idx + 1) / resolvedCount;
  }];
  
  // Run completion block
  _completionBlock();
}

- (IBAction)selectAllAction:(id)sender {
  NSInteger count = [_conflictItems count];
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
  }
}

- (IBAction)selectNoneAction:(id)sender {
  NSInteger count = [_conflictItems count];
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
  }
}

@end
