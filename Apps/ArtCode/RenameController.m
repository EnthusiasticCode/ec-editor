//
//  RenameController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 30/08/12.
//
//

#import "RenameController.h"
#import "UIImage+AppStyle.h"
#import "FileSystemDirectory.h"
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
  
  // Signal for the renameTextField contents
  RACSignal * renameTextFieldSignal = [[RACAble(self.renameTextField) map:^RACSignal *(UITextField *textField) {
    return [[[[textField rac_textSignal] throttle:0.2] distinctUntilChanged] startWith:textField.text];
  }] switchToLatest];
  
  // Update the file icon when the extension changes
  [[RACSignal combineLatest:@[[[renameTextFieldSignal map:^NSString *(NSString *x) {
    return [x pathExtension];
  }] distinctUntilChanged], RACAble(self.renameFileIcon)]] subscribeNext:^(RACTuple *xs) {
    NSString *extension = xs.first;
    UIImageView *renameFileIcon = xs.second;
    renameFileIcon.image = [UIImage styleDocumentImageWithFileExtension:extension];
  }];
  
  // Update the text field when the file is renamed from somewhere else
  [[RACSignal combineLatest:@[ RACAble(self.renameTextField), item.nameSignal ]] subscribeNext:^(RACTuple *xs) {
    UITextField *renameTextField = xs.first;
    NSString *name = xs.second;
    renameTextField.text = name;
    [renameTextField sendActionsForControlEvents:UIControlEventEditingChanged];
  }];
  
  // Update the alsoRenameItems when the item's name or siblings change
  [[[[RACSignal combineLatest:@[ [[item.parentSignal map:^RACSignal *(FileSystemDirectory *parent) {
    return parent.childrenSignal;
  }] switchToLatest], item.nameSignal ]] map:^(RACTuple *tuple) {
		RACTupleUnpack(NSArray *children, NSString *fullName) = tuple;
		NSString *name = [fullName stringByDeletingPathExtension];
		NSMutableArray *alsoRenameItems = [NSMutableArray array];
		
		for (FileSystemItem *child in children) {
			NSString *childFullName = child.name;
			if (![childFullName isEqualToString:fullName] && [childFullName.stringByDeletingPathExtension isEqualToString:name]) [alsoRenameItems addObject:child];
		}
		
		return alsoRenameItems;
  }] catchTo:RACSignal.empty] toProperty:@keypath(self.alsoRenameItems) onObject:self];
  
  // Reset the selectedAlsoRenameItems when alsoRenameItems change
  [[RACAble(self.alsoRenameItems) map:^NSMutableSet *(NSArray *alsoRenameItems) {
    return [NSMutableSet set];
  }] toProperty:@keypath(self.selectedAlsoRenameItems) onObject:self];
  
  // Hide or show the alsoRenameTableView when needed
  [[RACSignal combineLatest:@[RACAble(self.alsoRenameItems), RACAble(self.alsoRenameView), RACAble(self.alsoRenameTableView)]] subscribeNext:^(RACTuple *xs) {
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
  [[RACSignal combineLatest:@[renameTextFieldSignal, RACAble(self.alsoRenameItems), RACAble(self.alsoRenameTableView)]] subscribeNext:^(RACTuple *xs) {
    NSArray *items = xs.second;
    UITableView *tableView = xs.third;
    if (items.count > 0) {
      [tableView reloadData];
    }
  }];
  
  return self;
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
  
  cell.item = (self.alsoRenameItems)[indexPath.row];
  if ([self.selectedAlsoRenameItems containsObject:cell.item]) {
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  }
  cell.renameString = self.renameTextField.text;

  return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedAlsoRenameItems addObject:(self.alsoRenameItems)[indexPath.row]];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  [self.selectedAlsoRenameItems removeObject:(self.alsoRenameItems)[indexPath.row]];
}

#pragma mark - Private methods

- (void)_doneAction:(id)sender {
  // TODO: checks on new name?
  NSString *newFullName = self.renameTextField.text;
  NSString *newName = newFullName.stringByDeletingPathExtension;
	NSString *oldFullName = _item.name;
	NSString *oldName = oldFullName.stringByDeletingPathExtension;
  NSArray *alsoRenameItems = self.alsoRenameItems;
  
	NSMutableArray *renameSignals = [NSMutableArray arrayWithCapacity:alsoRenameItems.count];
	[renameSignals addObject:[_item renameTo:newFullName]];
	for (FileSystemItem *item in alsoRenameItems) {
		[renameSignals addObject:[item renameTo:[newName stringByAppendingString:[item.name substringFromIndex:oldName.length]]]];
	}
	
  [[RACSignal zip:renameSignals] subscribeError:^(NSError *error) {
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
  
  [[[RACSignal combineLatest:@[[[RACAble(item) map:^(FileSystemItem *item) {
    return item.nameSignal;
  }] switchToLatest], RACAble(renameString)]] map:^NSString *(RACTuple *tuple) {
		RACTupleUnpack(NSString *itemName, NSString *renameString) = tuple;
    return [NSString stringWithFormat:L(@"Rename to: %@"), [renameString.stringByDeletingPathExtension stringByAppendingPathExtension:itemName.pathExtension]];
  }] toProperty:@keypath(self.detailTextLabel.text) onObject:self];
  
  return self;
}

@end
