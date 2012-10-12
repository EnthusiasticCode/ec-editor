//
//  BaseFileBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 08/10/12.
//
//

#import "LocalFileListController.h"
#import "FileSystemItem.h"
#import "HighlightTableViewCell.h"
#import "ProgressTableViewCell.h"
#import "UIImage+AppStyle.h"
#import "NSURL+Utilities.h"


@interface LocalFileListController ()
/// An array of RACTuples (itemURL, progressSubscribable)
@property (nonatomic, strong) NSArray *progressItems;
@end

@implementation LocalFileListController {
  NSMutableArray *_selectedItems;
  NSMutableArray *_progressItems;
}

static void _init(LocalFileListController *self) {
  // RAC
  __weak LocalFileListController *this = self;
  
  RAC(self.filteredItems) = [[RACSubscribable combineLatest:@[
                              // Subscribable to get filtered files
                              [[[[RACAble(self.locationURL)
                                  select:^id(NSURL *url) {
                                    return [FileSystemItem directoryWithURL:url];
                                  }] switch]
                                select:^id(FileSystemItem *directory) {
                                  return [directory childrenFilteredByAbbreviation:this.searchBarTextSubject];
                                }] switch],
                              // Subscribable with progress items
                              RACAbleWithStart(self.progressItems)]]
                             select:^id(RACTuple *itemsTuple) {
                               if (itemsTuple.second == nil) {
                                 // Just show the directory items
                                 return itemsTuple.first;
                               } else {
                                 // Combine arrays and sort
                                 return [[itemsTuple.first arrayByAddingObjectsFromArray:itemsTuple.second] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                   // Both elements are in any case RACTuples with an NSURL as first
                                   return [[[obj1 first] lastPathComponent] compare:[[obj2 first] lastPathComponent]];
                                 }];
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

- (void)loadView {
  [super loadView];
  
  [self.tableView registerNib:[UINib nibWithNibName:@"ProgressTableViewCell" bundle:nil] forCellReuseIdentifier:@"progressCell"];
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

- (void)addProgressItemWithURL:(NSURL *)url progressSubscribable:(RACSubscribable *)progressSubscribable {
  [self willChangeValueForKey:@"progressItems"];
  if (!_progressItems) {
    _progressItems = [[NSMutableArray alloc] init];
  }
  RACTuple *progressItem = [RACTuple tupleWithObjects:url, progressSubscribable, nil];
  [_progressItems addObject:progressItem];
  
  [self didChangeValueForKey:@"progressItems"];
  
  // RAC
  @weakify(self);
  [[progressSubscribable finally:^{
    @strongify(self);
    // Remove the progress item when it completes
    [self willChangeValueForKey:@"progressItems"];
    [self->_progressItems removeObject:progressItem];
    [self didChangeValueForKey:@"progressItems"];
  }] subscribeCompleted:^{
    // TODO bezel alert with successful downlad
  }];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  RACTuple *item = [self.filteredItems objectAtIndex:indexPath.row];
  NSURL *itemURL = item.first;
  UITableViewCell *cell = nil;
  if ([item.second isKindOfClass:[RACSubscribable class]]) {
    ProgressTableViewCell *progressCell = (ProgressTableViewCell *)[tView dequeueReusableCellWithIdentifier:@"progressCell"];
    cell = progressCell;
    
    [progressCell setProgressSubscribable:item.second];
  } else {
    HighlightTableViewCell *highlightCell = (HighlightTableViewCell *)[super tableView:tView cellForRowAtIndexPath:indexPath];
    cell = highlightCell;
    
    highlightCell.textLabelHighlightedCharacters = item.second;
    
    // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
    if ([_selectedItems containsObject:itemURL])
      [tView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  }
  
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
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  RACTuple *item = [self.filteredItems objectAtIndex:indexPath.row];
  return ![item.second isKindOfClass:[RACSubscribable class]];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NSURL *itemURL = [[self.filteredItems objectAtIndex:indexPath.row] first];
  LocalFileListController *nextFileBrowserController = [[LocalFileListController alloc] init];
  nextFileBrowserController.locationURL = itemURL;
  nextFileBrowserController.editing = self.editing;
  [self.navigationController pushViewController:nextFileBrowserController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  if (self.isEditing) {
    [self willChangeValueForKey:@"selectedItems"];
    [_selectedItems addObject:[(RACTuple *)[self.filteredItems objectAtIndex:indexPath.row] first]];
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
    [_selectedItems removeObject:[(RACTuple *)[self.filteredItems objectAtIndex:indexPath.row] first]];
    [self didChangeValueForKey:@"selectedItems"];
  }
  [super tableView:tableView didDeselectRowAtIndexPath:indexPath];
}

@end
