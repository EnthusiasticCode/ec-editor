//
//  BaseFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/10/12.
//
//

#import "LocalFileListController.h"
#import "FileSystemDirectory.h"
#import "FileSystemItemCell.h"
#import "ProgressTableViewCell.h"
#import "UIImage+AppStyle.h"
#import "NSURL+Utilities.h"


@interface LocalFileListController ()
/// An array of RACTuples (itemURL, progressSignal)
@property (nonatomic, strong) NSArray *progressItems;
@end

@implementation LocalFileListController {
  NSMutableArray *_selectedItems;
  NSMutableArray *_progressItems;
}

static void _init(LocalFileListController *self) {
  // RAC
  @weakify(self);
  RAC(self.filteredItems) = [[RACSignal combineLatest:@[
                              // Signal to get filtered files
                              [[RACAble(self.locationDirectory)
                                map:^id(FileSystemDirectory *directory) {
                                  @strongify(self);
																	return [directory childrenSignalFilteredByAbbreviation:self.searchBarTextSubject];
                                }] switchToLatest],
                              // Signal with progress items
                              RACAbleWithStart(self.progressItems)]]
                             map:^id(RACTuple *itemsTuple) {
                               if (itemsTuple.second == nil) {
                                 // Just show the directory items
                                 return itemsTuple.first;
                               } else {
                                 // Combine arrays with progress items on top
                                 return [itemsTuple.second arrayByAddingObjectsFromArray:itemsTuple.first];
                               }
                             }];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (!self) {
    return nil;
  }
  _init(self);
  return self;
}

- (id)init {
  self = [super initWithNibName:nil bundle:nil];
  if (!self) {
    return nil;
  }
  _init(self);
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = L(@"Filter files in this folder");
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
  [super setEditing:editing animated:animated];
  [self willChangeValueForKey:@"selectedItems"];
  if (editing) {
    _selectedItems = [[NSMutableArray alloc] init];
  } else {
    _selectedItems = nil;
  }
  [self didChangeValueForKey:@"selectedItems"];
}

- (void)addProgressItemWithName:(NSString *)name progressSignal:(RACSignal *)progressSignal {
  [self willChangeValueForKey:@"progressItems"];
  if (!_progressItems) {
    _progressItems = [[NSMutableArray alloc] init];
  }
  RACTuple *progressItem = [RACTuple tupleWithObjects:name, progressSignal, nil];
  [_progressItems addObject:progressItem];
  
  [self didChangeValueForKey:@"progressItems"];
  
  // RAC
  @weakify(self);
  [[progressSignal finally:^{
    @strongify(self);
    // Remove the progress item when it completes
    [self willChangeValueForKey:@"progressItems"];
    [self->_progressItems removeObject:progressItem];
    [self didChangeValueForKey:@"progressItems"];
  }] subscribeCompleted:^{
    // TODO: bezel alert with successful downlad
  }];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  RACTuple *tuple = (self.filteredItems)[indexPath.row];
  UITableViewCell *cell = nil;
  if ([tuple.second isKindOfClass:[RACSignal class]]) {
    static NSString * const progressCellIdentifier = @"progressCell";
    ProgressTableViewCell *progressCell = (ProgressTableViewCell *)[tView dequeueReusableCellWithIdentifier:progressCellIdentifier];
    if (!progressCell) {
      progressCell = [[ProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:progressCellIdentifier];
    }
    cell = progressCell;
    
    [progressCell setProgressSignal:tuple.second];
    
    // The first item is an URL
    NSURL *itemURL = tuple.first;
    cell.textLabel.text = itemURL.lastPathComponent;
    
    if ([itemURL isDirectory]) {
      cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    } else {
      cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[itemURL pathExtension]];
      cell.accessoryType = UITableViewCellAccessoryNone;
      cell.editingAccessoryType = UITableViewCellAccessoryNone;
    }
  } else {
    static NSString * const highlightCellIdentifier = @"cell";
    FileSystemItemCell *highlightCell = (FileSystemItemCell *)[tView dequeueReusableCellWithIdentifier:highlightCellIdentifier];
    if (!highlightCell) {
      highlightCell = [[FileSystemItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:highlightCellIdentifier];
    }
    cell = highlightCell;
    
    highlightCell.textLabelHighlightedCharacters = tuple.second;
    
    // The first item is a file system item
    highlightCell.item = tuple.first;
    
    // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
    if ([_selectedItems containsObject:tuple.first]) {
      [tView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
  }
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  RACTuple *item = (self.filteredItems)[indexPath.row];
  return ![item.second isKindOfClass:[RACSignal class]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  FileSystemItem *item = [(self.filteredItems)[indexPath.row] first];
  LocalFileListController *nextFileBrowserController = [[LocalFileListController alloc] init];
  nextFileBrowserController.locationDirectory = (FileSystemDirectory *)item;
  nextFileBrowserController.editing = self.editing;
  [self.navigationController pushViewController:nextFileBrowserController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems addObject:[(RACTuple *)(self.filteredItems)[indexPath.row] first]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  return [self tableView:tableView canEditRowAtIndexPath:indexPath] ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems removeObject:[(RACTuple *)(self.filteredItems)[indexPath.row] first]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

@end
