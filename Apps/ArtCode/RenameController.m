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
#import "FileSystemItemCell.h"


@interface RenameController ()

@property (nonatomic, strong) NSArray *alsoRenameItems;
@property (nonatomic, strong) NSMutableSet *selectedAlsoRenameItems;

@end

@interface RenameCell : FileSystemItemCell

@property (nonatomic, strong) NSString *renameString;

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
    return [[[[textField rac_textSubscribable] throttle:0.2] distinctUntilChanged] startWith:textField.text];
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
    [renameTextField sendActionsForControlEvents:UIControlEventEditingChanged];
  }];
  
  // Update the alsoRenameItems when the item's name or siblings change
  [[[[RACSubscribable combineLatest:@[[[[item parent] select:^id<RACSubscribable>(FileSystemDirectory *parent) {
    return [parent children];
  }] switch], [item name]]] select:^id<RACSubscribable>(RACTuple *xs) {
    return [RACSubscribable createSubscribable:^RACDisposable *(id<RACSubscriber> subscriber) {
      NSArray *children = xs.first;
      NSString *fullName = xs.second;
      NSString *name = [fullName stringByDeletingPathExtension];
      NSMutableArray *alsoRenameItems = [[NSMutableArray alloc] init];
      return [[[[children.rac_toSubscribable selectMany:^id<RACSubscribable>(FileSystemItem *x) {
        return [RACSubscribable combineLatest:@[[RACSubscribable return:x], [x.name take:1]]];
      }] where:^BOOL(RACTuple *ys) {
        NSString *itemName = ys.second;
        return ![itemName isEqualToString:fullName] && [[itemName stringByDeletingPathExtension] isEqual:name];
      }] select:^id(RACTuple *ys) {
        return ys.first;
      }] subscribeNext:^(FileSystemItem *x) {
        [alsoRenameItems addObject:x];
      } error:^(NSError *error) {
        [subscriber sendError:error];
      } completed:^{
        [subscriber sendNext:alsoRenameItems];
        [subscriber sendCompleted];
      }];
    }];
  }] switch] toProperty:@keypath(self.alsoRenameItems) onObject:self];
  
  // Reset the selectedAlsoRenameItems when alsoRenameItems change
  [[RACAble(self.alsoRenameItems) select:^NSMutableSet *(NSArray *alsoRenameItems) {
    return [[NSMutableSet alloc] init];
  }] toProperty:@keypath(self.selectedAlsoRenameItems) onObject:self];
  
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
  RenameCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (!cell) {
    cell = [[RenameCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
  }
  
  cell.item = [self.alsoRenameItems objectAtIndex:indexPath.row];
  if ([self.selectedAlsoRenameItems containsObject:cell.item]) {
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  }
  cell.renameString = self.renameTextField.text;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedAlsoRenameItems addObject:[self.alsoRenameItems objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedAlsoRenameItems removeObject:[self.alsoRenameItems objectAtIndex:indexPath.row]];
}

#pragma mark - Private methods

- (void)_doneAction:(id)sender {
  // TODO: checks on new name?
  NSString *newFullName = self.renameTextField.text;
  NSString *newName = newFullName.stringByDeletingPathExtension;
  NSArray *alsoRenameItems = self.alsoRenameItems;
  
  @weakify(self);
  [[[[_item.name take:1] selectMany:^id<RACSubscribable>(NSString *x) {
    @strongify(self);
    if (!self) {
      return nil;
    }
    return [RACSubscribable combineLatest:@[[RACSubscribable return:x], [self->_item renameTo:newFullName]]];
  }] selectMany:^id<RACSubscribable>(RACTuple *xs) {
    @strongify(self);
    NSString *oldFullName = xs.first;
    NSString *oldName = [oldFullName stringByDeletingPathExtension];
    return [[self.selectedAlsoRenameItems rac_toSubscribable] selectMany:^id<RACSubscribable>(FileSystemItem *x) {
      return [[x.name take:1] selectMany:^id<RACSubscribable>(NSString *y) {
        NSString *newFullName = [newName stringByAppendingString:[y substringFromIndex:oldName.length]];
        return [x renameTo:newFullName];
      }];
    }];
  }] subscribeError:^(NSError *error) {
    _completionHandler(0, error);
  } completed:^{
    _completionHandler(alsoRenameItems.count + 1, nil);
  }];
}

@end

@implementation RenameCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (!self) {
    return nil;
  }
  
  [[[RACSubscribable combineLatest:@[[[RACAble(item) select:^id<RACSubscribable>(FileSystemItem *x) {
    return x.name;
  }] switch], RACAble(renameString)]] select:^NSString *(RACTuple *xs) {
    NSString *itemName = xs.first;
    NSString *renameString = xs.second;
    return [NSString stringWithFormat:L(@"Rename to: %@"), [renameString.stringByDeletingPathExtension stringByAppendingPathExtension:itemName.pathExtension]];
  }] toProperty:@keypath(self.detailTextLabel.text) onObject:self];
  
  return self;
}

@end
