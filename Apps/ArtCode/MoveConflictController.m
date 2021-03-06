//
//  MoveConflictController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoveConflictController.h"
#import "NSURL+Utilities.h"
#import "UIImage+AppStyle.h"
#import <ReactiveCocoaIO/ReactiveCocoaIO.h>
#import "RCIOItemCell.h"


@implementation MoveConflictController {
  NSMutableArray *_resolvedItems;
  NSMutableArray *_conflictItems;
  RACSignal *(^_signalBlock)(RCIOItem *);
  RACSubject *_moveSubject;
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
  
  [(self.toolbar.items)[0] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
  [(self.toolbar.items)[1] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return _conflictItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString * const cellIdentifier = @"Cell";
  RCIOItemCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil) {
    cell = [[RCIOItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  RCIOItem *item = _conflictItems[indexPath.row];
  cell.item = item;
  
  return cell;
}

#pragma mark - Public Methods

- (RACSignal *)moveItems:(NSArray *)items toFolder:(RCIODirectory *)destinationFolder usingSignalBlock:(RACSignal * (^)(RCIOItem *, RCIODirectory *))signalBlock {
  ASSERT_MAIN_QUEUE();
  _signalBlock = ^RACSignal *(RCIOItem *item) {
    return signalBlock(item, destinationFolder);
  };
  RACReplaySubject *moveSubject = [RACReplaySubject replaySubjectWithCapacity:1];
  _moveSubject = moveSubject;
	items = items.copy;
  @weakify(self);
  
	[[destinationFolder.childrenSignal take:1] subscribeNext:^(NSArray *destinationChildren) {
		@strongify(self);
		if (!self) return;
		
		NSMutableArray *conflictItems = [NSMutableArray arrayWithCapacity:MIN(items.count, destinationChildren.count)];
		NSMutableArray *resolvedItems = [NSMutableArray arrayWithCapacity:items.count];
		for (RCIOItem *item in items) {
			[resolvedItems addObject:item];
		}
		
		// Compare the names to find conflicts
		for (RCIOItem *child in destinationChildren) {
			NSString *childName = child.name;
			for (RCIOItem *item in items) {
				if ([item.name isEqualToString:childName]) {
					[resolvedItems removeObject:item];
					[conflictItems addObject:item];
					break;
				}
			}
		}
		
		self->_conflictItems = conflictItems;
		self->_resolvedItems = resolvedItems;
		
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
		self.navigationItem.title = @"Select files to replace";	} error:^(NSError *error) {
		[moveSubject sendError:error];
	}];
	
  return _moveSubject;
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
  NSMutableIndexSet *selectedIndexSet = [NSMutableIndexSet indexSet];
  for (NSIndexPath *selectedIndexPath in [self.conflictTableView indexPathsForSelectedRows]) {
    [selectedIndexSet addIndex:selectedIndexPath.row];
  }
  [_resolvedItems addObjectsFromArray:[_conflictItems objectsAtIndexes:selectedIndexSet]];
  [_conflictItems removeObjectsAtIndexes:selectedIndexSet];
  [self.conflictTableView deleteRowsAtIndexPaths:[self.conflictTableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationAutomatic];
  
  // Processing
  ASSERT(_signalBlock);
  @weakify(self);
  [[RACSignal zip:[_resolvedItems.rac_sequence.eagerSequence map:^RACSignal *(RCIOItem *x) {
    @strongify(self);
    if (!self) {
      return nil;
    }
    return self->_signalBlock(x);
  }]] subscribe:_moveSubject];
}

- (IBAction)selectAllAction:(id)sender {
  NSInteger count = _conflictItems.count;
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
  }
}

- (IBAction)selectNoneAction:(id)sender {
  NSInteger count = _conflictItems.count;
  for (NSInteger i = 0; i < count; ++i) {
    [self.conflictTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
  }
}

@end
