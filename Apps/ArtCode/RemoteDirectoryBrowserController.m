//
//  UploadBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 27/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemoteDirectoryBrowserController.h"
#import "HighlightTableViewCell.h"
#import "UIImage+AppStyle.h"
#import <Connection/CKConnectionRegistry.h>

@interface RemoteDirectoryBrowserController (Protected)

- (void)_changeToDirectory:(NSString *)directory;

@end


@implementation RemoteDirectoryBrowserController {
    NSArray *_itemsOnlyDirectories;
}

- (NSURL *)selectedURL
{
    if (self.tableView.indexPathForSelectedRow != nil)
        return [self.URL URLByAppendingPathComponent:[[self.filteredItems objectAtIndex:self.tableView.indexPathForSelectedRow.row] objectForKey:cxFilenameKey]];
    return self.URL;
}

- (void)setURL:(NSURL *)URL
{
    // Avoid disconnection when view did disapear.
    if (URL == nil)
        return;
    
    [super setURL:URL];
    if ([URL.path length] == 0)
        self.navigationItem.title = URL.host;
    else
        self.navigationItem.title = [URL.path lastPathComponent];
}

- (NSArray *)filteredItems
{
    if (!_itemsOnlyDirectories)
    {
        NSMutableArray *items = [NSMutableArray arrayWithCapacity:[[super filteredItems] count]];
        for (NSDictionary *item in [super filteredItems])
        {
            if ([item objectForKey:NSFileType] == NSFileTypeDirectory)
                [items addObject:item];
        }
        _itemsOnlyDirectories = [items copy];
    }
    return _itemsOnlyDirectories;
}

- (void)invalidateFilteredItems
{
    _itemsOnlyDirectories = nil;
    [super invalidateFilteredItems];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.tableHeaderView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([self.connection delegate] != self)
    {
        [self _changeToDirectory:self.URL.path];
    }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self.filteredItems objectAtIndex:indexPath.row];
    RemoteDirectoryBrowserController *nextController = [[RemoteDirectoryBrowserController alloc] initWithConnection:self.connection url:self.URL];
    [nextController setURL:[self.URL URLByAppendingPathComponent:[item objectForKey:cxFilenameKey]]];
    
    [self.navigationController pushViewController:nextController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Do nothing
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Do nothing
}

@end
