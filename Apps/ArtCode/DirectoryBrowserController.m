//
//  DirectoryBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DirectoryBrowserController.h"
#import "UIImage+AppStyle.h"

#import "NSString+PluralFormat.h"

@interface DirectoryBrowserController (/*Private methods*/)

- (void)_enumerateDirectoriesAtURL:(NSURL *)rootURL usignBlock:(void(^)(NSURL *url, BOOL *stop))block;

@end

@interface DirectoryListItem : NSObject

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, readonly) NSUInteger fileCount;
@property (nonatomic, readonly) NSUInteger subDirectoryCount;

- (id)initWithURL:(NSURL *)url;
- (NSString *)details;

@end

#pragma mark -

@implementation DirectoryBrowserController {
@private
    NSMutableArray *_directoryItemsList;
}

@synthesize URL;

- (void)setURL:(NSURL *)value
{
    if (value == URL)
        return;
    URL = value;
    self.navigationItem.title = [[value lastPathComponent] stringByDeletingPathExtension];
    if (!_directoryItemsList)
        _directoryItemsList = [NSMutableArray new];
    else
        [_directoryItemsList removeAllObjects];
    [self _enumerateDirectoriesAtURL:value usignBlock:^(NSURL *url, BOOL *stop) {
        [_directoryItemsList addObject:[[DirectoryListItem alloc] initWithURL:url]];
    }];
    [self.tableView reloadData];
}

- (NSURL *)selectedURL
{
    NSIndexPath *selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath == nil)
        return self.URL;
    return [[_directoryItemsList objectAtIndex:selectedIndexPath.row] URL];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_directoryItemsList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    }
    
    DirectoryListItem *item = [_directoryItemsList objectAtIndex:[indexPath indexAtPosition:1]];
    cell.accessoryType = item.subDirectoryCount ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    cell.textLabel.text = [item.URL lastPathComponent];
    cell.detailTextLabel.text = [item details];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    if (self.navigationController != nil)
    {
        DirectoryListItem *item = [_directoryItemsList objectAtIndex:[indexPath indexAtPosition:1]];
        ECASSERT(item.subDirectoryCount != 0);
        
        DirectoryBrowserController *nextBrowser = [[DirectoryBrowserController alloc] initWithStyle:self.tableView.style];
        nextBrowser.URL = item.URL;
        nextBrowser.navigationItem.rightBarButtonItem = self.navigationItem.rightBarButtonItem;
        
        [self.navigationController pushViewController:nextBrowser animated:YES];
    }
}

#pragma mark - Private methods


- (void)_enumerateDirectoriesAtURL:(NSURL *)rootURL usignBlock:(void(^)(NSURL *url, BOOL *stop))block
{
    ECASSERT(rootURL != nil && block != nil);
    
    BOOL stop = NO;
    NSNumber *isDirectory = nil;
    for (NSURL *url in [[NSFileManager new] enumeratorAtURL:rootURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil])
    {
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue])
        {
            block(url, &stop);
            if (stop)
                break;
        }
    }
}

@end


@implementation DirectoryListItem

@synthesize URL, fileCount, subDirectoryCount;

- (id)initWithURL:(NSURL *)itemUrl
{
    self = [super init];
    if (!self)
        return nil;
    URL = itemUrl;
    NSNumber *isDirectory = nil;
    for (NSURL *url in [[NSFileManager defaultManager] enumeratorAtURL:itemUrl includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants errorHandler:nil])
    {
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue])
            subDirectoryCount++;
        else
            fileCount++;
    }
    return self;
}

- (NSString *)details
{
    if (fileCount == 0 && subDirectoryCount == 0)
        return @"Empty";
    // TODO singluar and plural
    NSString *result = fileCount ? [NSString stringWithFormatForSingular:@"%u file" plural:@"%u files" count:fileCount] : nil;
    if (subDirectoryCount)
        result = result ? [result stringByAppendingFormatForSingular:@", %u folder" plural:@", %u folders" count:subDirectoryCount] : [NSString stringWithFormatForSingular:@"%u folder" plural:@"%u folders" count:subDirectoryCount];
    return result;
}

@end
