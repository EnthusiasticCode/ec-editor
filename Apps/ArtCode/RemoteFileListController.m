//
//  RemoteFileListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 29/09/12.
//
//

#import "RemoteFileListController.h"

#import "ArtCodeRemote.h"
#import <Connection/CKConnectionRegistry.h>
#import "NSArray+ScoreForAbbreviation.h"

#import "RemoteNavigationController.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"


@implementation RemoteFileListController {
  ArtCodeRemote *_remote;
  id<CKConnection> _connection;
  NSString *_remotePath;
  
  NSArray *_directoryContent;
  NSArray *_filteredItems;
  NSArray *_filteredItemsHitMasks;

  NSMutableArray *_selectedItems;
}

- (id)initWithArtCodeRemote:(ArtCodeRemote *)remote connection:(id<CKConnection>)connection path:(NSString *)remotePath {
  self = [super init];
  if (!self)
    return nil;
  _remote = remote;
  _connection = connection;
  _remotePath = remotePath;
  return self;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  _directoryContent = nil;
}

- (NSArray *)filteredItems {
  // In no content is present, returns nil and ask for a refresh
  if (!_directoryContent) {
    [self _listContentOfDirectoryWithFullPath:_remotePath];
    return nil;
  }
  
  // Filtering
  if ([self.searchBar.text length] != 0) {
    NSArray *hitsMask = nil;
    _filteredItems = [_directoryContent sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitsMask extrapolateTargetStringBlock:^NSString *(NSDictionary *element) {
      return [element objectForKey:cxFilenameKey];
    }];
    _filteredItemsHitMasks = hitsMask;
  }
  else
  {
    _filteredItems = _directoryContent;
    _filteredItemsHitMasks = nil;
  }
  return _filteredItems;
}

- (void)invalidateFilteredItems {
  _filteredItems = nil;
  _filteredItemsHitMasks = nil;
  [_selectedItems removeAllObjects];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.searchBar.placeholder = @"Filter files in this remote folder";
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  [super setEditing:editing animated:animated];
  [_selectedItems removeAllObjects];
}


#pragma mark Connection Directory Management

//- (void)connection:(id <CKPublishingConnection>)con didChangeToDirectory:(NSString *)dirPath error:(NSError *)error
//{
//  [con directoryContents];
//}

- (void)connection:(id <CKPublishingConnection>)con didReceiveContents:(NSArray *)contents ofDirectory:(NSString *)dirPath error:(NSError *)error {
  [self setLoading:NO];
  
  // Cache results
  _directoryContent = contents;
  [self invalidateFilteredItems];
  [self.tableView reloadData];
  
  // Enable non-editing buttons
  for (UIBarButtonItem *barItem in self.toolNormalItems)
  {
    [(UIButton *)barItem.customView setEnabled:YES];
  }
}

//- (void)connection:(id <CKPublishingConnection>)con didCreateDirectory:(NSString *)dirPath error:(NSError *)error
//{
//
//}
//
//- (void)connection:(id <CKConnection>)con didRename:(NSString *)fromPath to:(NSString *)toPath error:(NSError *)error
//{
//
//}
//
//- (void)connection:(id <CKConnection>)con didSetPermissionsForFile:(NSString *)path error:(NSError *)error
//{
//
//}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
  
  NSDictionary *directoryItem = [self.filteredItems objectAtIndex:indexPath.row];
  cell.textLabel.text = [directoryItem objectForKey:cxFilenameKey];
  cell.textLabelHighlightedCharacters = _filteredItemsHitMasks ? [_filteredItemsHitMasks objectAtIndex:indexPath.row] : nil;
  if ([directoryItem objectForKey:NSFileType] == NSFileTypeDirectory)
  {
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
  }
  else
  {
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.imageView.image = [UIImage styleDocumentImageWithFileExtension:[[directoryItem objectForKey:cxFilenameKey] pathExtension]];
  }
  // TODO also use NSFileSize
  // Select item to maintain selection on filtering
  if ([_selectedItems containsObject:directoryItem])
    [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
  
  return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Private Methods

- (void)setLoading:(BOOL)loading {
  
}

- (void)_listContentOfDirectoryWithFullPath:(NSString *)fullPath {
  [self setLoading:YES];
  
  if (![_connection isConnected]) {
    // There is no connection, this controller has no use, popping it
    [self.remoteNavigationController popToRootViewControllerAnimated:YES];
    return;
  }
  
  [_connection setDelegate:self];
  [_connection changeToDirectory:fullPath.length ? fullPath : @"/"];
  [_connection directoryContents];
}

@end
