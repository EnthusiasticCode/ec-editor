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
#import "UIImage+AppStyle.h"
#import "NSURL+Utilities.h"

@implementation LocalFileListController

static void _init(LocalFileListController *self) {
  // RAC
  __weak LocalFileListController *this = self;
  
  RAC(self.filteredItems) = [[[[RACAble(self.locationURL)
                             select:^id(NSURL *url) {
                               return [FileSystemItem readItemAtURL:url];
                             }] switch]
                             select:^id(FileSystemItem *directory) {
                               return [directory childrenFilteredByAbbreviation:this.searchBarTextSubject];
                             }] switch];
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

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tView cellForRowAtIndexPath:indexPath];
  
  // Configure the cell
  RACTuple *item = [self.filteredItems objectAtIndex:indexPath.row];
  NSURL *itemURL = item.first;
  
  cell.textLabel.text = itemURL.lastPathComponent;
  cell.textLabelHighlightedCharacters = item.second;
  
  if ([itemURL isDirectory]) {
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.editingAccessoryType = UITableViewCellAccessoryDetailDisclosureButton;
  } else {
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[itemURL pathExtension]];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.editingAccessoryType = UITableViewCellAccessoryNone;
  }
  // Side effect. Select this row if present in the selected urls array to keep selection persistent while filtering
//  if ([_selectedItems containsObject:itemURL])
//    [tView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
  NSURL *itemURL = [[self.filteredItems objectAtIndex:indexPath.row] first];
  LocalFileListController *nextFileBrowserController = [[LocalFileListController alloc] init];
  nextFileBrowserController.locationURL = itemURL;
  nextFileBrowserController.editing = self.editing;
  [self.navigationController pushViewController:nextFileBrowserController animated:YES];
}

@end
