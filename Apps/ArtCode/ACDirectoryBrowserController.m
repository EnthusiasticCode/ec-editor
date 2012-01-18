//
//  ACDirectoryBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 18/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACDirectoryBrowserController.h"


@interface ACDirectoryBrowserController (/*Private methods*/)

@property (nonatomic, strong) NSURL *currentURL;

- (void)_enumerateDirectoriesAtURL:(NSURL *)rootURL usignBlock:(void(^)(NSURL *url, BOOL *stop))block;

@end

@interface DirectoryListItem : NSObject

@property (nonatomic, strong, readonly) NSURL *URL;
@property (nonatomic, readonly) NSUInteger fileCount;
@property (nonatomic, readonly) NSUInteger subDirectoryCount;

- (id)initWithURL:(NSURL *)url;

@end

#pragma mark -

@implementation ACDirectoryBrowserController {
@private
    NSMutableArray *_historyStack;
    NSMutableArray *_directoryItemsList;
}

@synthesize baseURL, currentURL;

- (void)setBaseURL:(NSURL *)value
{
    if (value == baseURL)
        return;
    [self willChangeValueForKey:@"baseURL"];
    baseURL = value;
    self.currentURL = value;
    [self didChangeValueForKey:@"baseURL"];
}

- (void)setCurrentURL:(NSURL *)value
{
    ECASSERT([[value path] hasPrefix:[self.baseURL path]]);
    
    if (value == currentURL)
        return;
    [self willChangeValueForKey:@"currentURL"];
    if (currentURL)
    {
        if (!_historyStack)
            _historyStack = [NSMutableArray new];
        [_historyStack addObject:currentURL];
    }
    currentURL = value;
    if (!_directoryItemsList)
        _directoryItemsList = [NSMutableArray new];
    else
        [_directoryItemsList removeAllObjects];
    [self _enumerateDirectoriesAtURL:value usignBlock:^(NSURL *url, BOOL *stop) {
        [_directoryItemsList addObject:[[DirectoryListItem alloc] initWithURL:url]];
    }];
    // TODO animate change
    [self.tableView reloadData];
    [self didChangeValueForKey:@"currentURL"];
}

#pragma mark - Navigation methods

- (void)moveBackOneLevelAction:(id)sender
{
    if ([_historyStack count] == 0)
        return;
    NSURL *backURL = [_historyStack lastObject];
    [_historyStack removeLastObject];
    self.currentURL = backURL;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)loadView
{
    [super loadView];
    
    self.toolbarItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(moveBackOneLevelAction:)]];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    DirectoryListItem *item = [_directoryItemsList objectAtIndex:[indexPath indexAtPosition:1]];
    cell.accessoryType = item.subDirectoryCount ? UITableViewCellAccessoryDetailDisclosureButton : UITableViewCellAccessoryNone;
    cell.textLabel.text = [item.URL lastPathComponent];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    DirectoryListItem *item = [_directoryItemsList objectAtIndex:[indexPath indexAtPosition:1]];
    ECASSERT(item.subDirectoryCount != 0);
    self.currentURL = item.URL;
}

#pragma mark - Private methods


- (void)_enumerateDirectoriesAtURL:(NSURL *)rootURL usignBlock:(void(^)(NSURL *url, BOOL *stop))block
{
    ECASSERT(rootURL != nil && block != nil);
    
    BOOL stop = NO;
    NSNumber *isDirectory = nil;
    for (NSURL *url in [[NSFileManager new] enumeratorAtURL:rootURL includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 errorHandler:nil])
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
    for (NSURL *url in [[NSFileManager defaultManager] enumeratorAtURL:itemUrl includingPropertiesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] options:0 errorHandler:nil])
    {
        [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
        if ([isDirectory boolValue])
            subDirectoryCount++;
        else
            fileCount++;
    }
    return self;
}

@end
