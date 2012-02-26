//
//  MoveConflictController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MoveConflictController.h"

#import "AppStyle.h"

#import "NSURL+Utilities.h"


@implementation MoveConflictController {
@private
    NSURL *_destinationURL;
    void (^_processingBlock)(NSURL *sourceURL, NSURL *destinationURL);
    void (^_completionBlock)(void);
}

@synthesize toolbar;

@synthesize conflictTableView, progressView;
@synthesize conflictURLs;

- (NSMutableArray *)conflictURLs
{
    if (!conflictURLs)
        conflictURLs = [NSMutableArray new];
    return conflictURLs;
}

#pragma mark - Controller lifecycle

- (id)init
{
    self = [super initWithNibName:@"MoveConflictController" bundle:nil];
    if (!self)
        return nil;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(doneAction:)];
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self init];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self.toolbar.items objectAtIndex:0] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[self.toolbar.items objectAtIndex:1] setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)viewDidUnload
{
    [self setConflictTableView:nil];
    [self setProgressView:nil];
    [self setToolbar:nil];
    conflictURLs = nil;
    _destinationURL = nil;
    _processingBlock = nil;
    _completionBlock = nil;
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table View Data Source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conflictURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * const cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    // TODO set icon
    cell.textLabel.text = [[self.conflictURLs objectAtIndex:[indexPath indexAtPosition:1]] lastPathComponent];
    
    return cell;
}

#pragma mark - Public methods

- (void)processItemURLs:(NSArray *)itemURLs toURL:(NSURL *)destinationURL usignProcessingBlock:(void (^)(NSURL *, NSURL *))processingBlock completion:(void (^)(void))completionBlock
{
    self.progressView.progress = 0;
    [self.conflictURLs removeAllObjects];
    
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fileManager = [NSFileManager new];
    CGFloat itemCount = [itemURLs count];
    [itemURLs enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
        [coordinator coordinateReadingItemAtURL:url options:0 writingItemAtURL:destinationURL options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
            newWritingURL = [newWritingURL URLByAppendingPathComponent:[newReadingURL lastPathComponent]];
            if ([fileManager fileExistsAtPath:[newWritingURL path]])
            {
                [self.conflictURLs addObject:newReadingURL];
            }
            else
            {
                processingBlock(newReadingURL, newWritingURL);
            }
        }];
        self.progressView.progress = (CGFloat)idx / itemCount;
    }];
    
    if ([self.conflictURLs count] == 0)
    {
        completionBlock();
        return;
    }
    
    _destinationURL = destinationURL;
    _processingBlock = [processingBlock copy];
    _completionBlock = [completionBlock copy];
    
    self.conflictTableView.hidden = NO;
    self.toolbar.hidden = NO;
    self.progressView.hidden = YES;
    [self.conflictTableView reloadData];
    [self.conflictTableView setEditing:YES animated:NO];
    self.navigationItem.title = @"Select files to replace";
}

- (void)doneAction:(id)sender
{
    [self replaceAction:self];
    if ([self.conflictURLs count] == 0)
        return;
    [self selectAllAction:self];
    [self keepOriginalAction:self];
}

- (IBAction)selectAllAction:(id)sender
{
    NSInteger count = [self.conflictURLs count];
    for (NSInteger i = 0; i < count; ++i)
    {
        [self.conflictTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
}

- (IBAction)selectNoneAction:(id)sender
{
    NSInteger count = [self.conflictURLs count];
    for (NSInteger i = 0; i < count; ++i)
    {
        [self.conflictTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:YES];
    }
}

- (IBAction)keepBothAction:(id)sender
{
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSFileManager *fileManager = [NSFileManager new];
    for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows])
    {
        NSURL *sourceURL = [self.conflictURLs objectAtIndex:[indexPath indexAtPosition:1]];
        NSURL *destinationURL = [_destinationURL URLByAppendingPathComponent:[sourceURL lastPathComponent]];
        // Get non conflicting destination URL
        NSURL *newDestinationURL = nil;
        NSUInteger count = 0;
        do {
            newDestinationURL = [destinationURL URLByAddingDuplicateNumber:++count];
        } while ([fileManager fileExistsAtPath:[newDestinationURL path]]);
        // Call processing
        [coordinator coordinateReadingItemAtURL:sourceURL options:0 writingItemAtURL:_destinationURL options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
            _processingBlock(sourceURL, newDestinationURL);
        }];
    }
    [self keepOriginalAction:sender];
}

- (IBAction)replaceAction:(id)sender
{
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    for (NSIndexPath *indexPath in [self.conflictTableView indexPathsForSelectedRows])
    {
        NSURL *sourceURL = [self.conflictURLs objectAtIndex:[indexPath indexAtPosition:1]];
        NSURL *destinationURL = [_destinationURL URLByAppendingPathComponent:[sourceURL lastPathComponent]];
        // Call processing
        [coordinator coordinateReadingItemAtURL:sourceURL options:0 writingItemAtURL:_destinationURL options:0 error:NULL byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
            _processingBlock(sourceURL, destinationURL);
        }];
    }
    [self keepOriginalAction:sender];
}

- (IBAction)keepOriginalAction:(id)sender
{
    NSArray *selectedRows = [self.conflictTableView indexPathsForSelectedRows];
    for (NSIndexPath *indexPath in [selectedRows reverseObjectEnumerator])
    {
        [self.conflictURLs removeObjectAtIndex:[indexPath indexAtPosition:1]];
    }
    [self.conflictTableView deleteRowsAtIndexPaths:selectedRows withRowAnimation:UITableViewRowAnimationAutomatic];
    if ([self.conflictURLs count] == 0 && _completionBlock)
        _completionBlock();
}

@end
