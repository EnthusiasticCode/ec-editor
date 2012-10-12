//
//  RenameController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/08/12.
//
//

#import "RenameController.h"
#import "UIImage+AppStyle.h"
#import "FileSystemItem.h"


@interface RenameController ()

@property (nonatomic, strong) NSArray *alsoRenameItems;

@end

@implementation RenameController {
  FileSystemItem *_item;
  void (^_completionHandler)(NSUInteger renamedCount, NSError *err);
}

#pragma mark - Controller lifecycle

- (instancetype)initWithRenameItem:(FileSystemItem *)item completionHandler:(void (^)(NSUInteger, NSError *))completionHandler {
  self = [super initWithNibName:@"RenameModalView" bundle:nil];
  if (!self) {
    return nil;
  }
  
  // The right button in a navigation controller will perform the operation
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Rename") style:UIBarButtonItemStyleDone target:self action:@selector(_doneAction:)];
  
  // Prepare for rename
  _item = item;
  _completionHandler = completionHandler;
  
  // RAC
  
  // Subscribable for the renameTextField contents
  id<RACSubscribable> renameTextFieldSubscribable = [[RACAble(self.renameTextField) select:^id<RACSubscribable>(UITextField *textField) {
    return [[[textField rac_textSubscribable] throttle:0.2] distinctUntilChanged];
  }] switch];
  
  // Update the file icon when the extension changes
  [[RACSubscribable combineLatest:@[[[renameTextFieldSubscribable select:^NSString *(NSString *x) {
    return [x pathExtension];
  }] distinctUntilChanged], RACAble(self.renameFileIcon)]] subscribeNext:^(RACTuple *xs) {
    NSString *extension = xs.first;
    UIImageView *renameFileIcon = xs.second;
    renameFileIcon.image = [UIImage styleDocumentImageWithFileExtension:extension];
  }];
  
  // Update the text field when the file is renamed from somewhere else
  [[RACSubscribable combineLatest:@[RACAble(self.renameTextField), [item name]]] subscribeNext:^(RACTuple *xs) {
    UITextField *renameTextField = xs.first;
    NSString *name = xs.second;
    renameTextField.text = name;
  }];
  
  // Update the alsoRenameItems when the item's name or siblings change
  [[[RACSubscribable combineLatest:@[[[[item parent] select:^id<RACSubscribable>(FileSystemItem *parent) {
    return [parent children];
  }] switch], [item name]]] select:^NSArray *(RACTuple *xs) {
    NSArray *children = xs.first;
    NSString *fullName = xs.second;
    NSString *name = [fullName stringByDeletingPathExtension];
    NSMutableArray *alsoRename = [[NSMutableArray alloc] init];
    for (FileSystemItem *item in children) {
      NSString *fileName = item.name.first;
      if ([fileName isEqual:fullName] || ![fileName hasPrefix:name]) {
        continue;
      }
      [alsoRename addObject:item];
    }
    return alsoRename;
  }] toProperty:RAC_KEYPATH_SELF(alsoRenameItems) onObject:self];
  
  // Hide or show the alsoRenameTableView when needed
  [[RACSubscribable combineLatest:@[RACAble(self.alsoRenameItems), RACAble(self.alsoRenameView), RACAble(self.alsoRenameTableView)]] subscribeNext:^(RACTuple *xs) {
    NSArray *items = xs.first;
    UIView *view = xs.second;
    UITableView *tableView = xs.third;
    if (items.count) {
      view.hidden = NO;
      tableView.editing = YES;
    } else {
      view.hidden = YES;
    }
  }];
  
  // Reload the alsoRenameTableView when needed
  [[RACSubscribable combineLatest:@[renameTextFieldSubscribable, RACAble(self.alsoRenameItems), RACAble(self.alsoRenameTableView)]] subscribeNext:^(RACTuple *xs) {
    NSArray *items = xs.second;
    UITableView *tableView = xs.third;
    if (items.count > 0) {
      [tableView reloadData];
    }
  }];
  
  return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.alsoRenameItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *cellIdentifier = @"default";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  NSString *text = [[(FileSystemItem *)[self.alsoRenameItems objectAtIndex:indexPath.row] name] first];
  cell.textLabel.text = text;
  cell.detailTextLabel.text = [NSString stringWithFormat:L(@"Rename to: %@"), [self.renameTextField.text.stringByDeletingPathExtension stringByAppendingPathExtension:text.pathExtension]];
  cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:text.pathExtension];
  
  return cell;
}

#pragma mark - Private methods

- (void)_doneAction:(id)sender {
  // TODO checks on new name?
  NSString *newFullName = self.renameTextField.text;
  NSString *newName = newFullName.stringByDeletingPathExtension;
  NSString *oldName = [_item.name.first stringByDeletingPathExtension];
  NSArray *alsoRenameItems = self.alsoRenameItems;
  
  [[_item renameTo:newFullName copy:NO] subscribeCompleted:^{
    [[[[alsoRenameItems rac_toSubscribable] select:^id<RACSubscribable>(FileSystemItem *item) {
      NSString *oldFullName = item.name.first;
      NSString *newFullName = [newName stringByAppendingString:[oldFullName substringFromIndex:oldName.length]];
      return [item renameTo:newFullName copy:NO];
    }] merge] subscribeError:^(NSError *error) {
      _completionHandler(0, error);
    } completed:^{
      _completionHandler(alsoRenameItems.count + 1, nil);
    }];
  }];
}

@end
