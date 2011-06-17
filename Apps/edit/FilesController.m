//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "FilesController.h"
#import "Project.h"
#import "Node.h"
#import "File.h"
#import "FileController.h"
#import "EditorController.h"
#import "Client.h"

static NSString *const DefaultIdentifier = @"Default";

static NSString *const FileSegueIdentifier = @"File";

@interface FilesController ()
@property (nonatomic, strong, readonly) NSMutableOrderedSet *files;
- (void)handleProjectChangedNotification:(NSNotification *)notification;
- (NSUInteger)addFilesForNode:(Node *)node;
- (NSUInteger)removeFilesForNode:(Node *)node;
- (void)removeAllFiles;
- (NSIndexSet *)indexesOfFilesToRemoveForNode:(Node *)node;
@end

@implementation FilesController

@synthesize files = _files;

- (NSMutableOrderedSet *)files
{
    if (!_files)
    {
        _files = [NSMutableOrderedSet orderedSetWithOrderedSet:[[Client sharedClient].currentProject children]];
        for (Node *node in _files)
            [node addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
        NSUInteger count = [_files count];
        for (NSUInteger i = 0; i < count; ++i)
        {
            Node *node = [_files objectAtIndex:i];
            NSUInteger addedFilesCount = [self addFilesForNode:node];
            i += addedFilesCount;
            count += addedFilesCount;
        }
    }
    return _files;
}

- (void)removeAllFiles
{
    for (Node *node in _files)
        [node removeObserver:self forKeyPath:@"collapsed"];
    _files = nil;
}

- (NSUInteger)addFilesForNode:(Node *)node
{
    ECASSERT([_files containsObject:node]);
    NSUInteger addedFilesCount = 0;
    NSUInteger nodeIndex = [_files indexOfObject:node];
    ECASSERT(nodeIndex != NSNotFound);
    NSOrderedSet *children = nil;
    if (!node.collapsed)
        children = [node children];
    if ([children count])
    {
        [self.tableView beginUpdates];
        NSUInteger insertionIndex = nodeIndex + 1;
        for (Node *childNode in children)
        {
            [_files insertObject:childNode atIndex:insertionIndex];
            [childNode addObserver:self forKeyPath:@"collapsed" options:NSKeyValueObservingOptionNew context:NULL];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertionIndex inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            insertionIndex++;
            addedFilesCount++;
            NSUInteger childAddedFilesCount = [self addFilesForNode:childNode];
            insertionIndex += childAddedFilesCount;
            addedFilesCount += childAddedFilesCount;
        }
        [self.tableView endUpdates];
    }
    return addedFilesCount;
}

- (NSUInteger)removeFilesForNode:(Node *)node
{
    ECASSERT([_files containsObject:node]);
    NSIndexSet *indexes = [self indexesOfFilesToRemoveForNode:node];
    if (![indexes count])
        return 0;
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        [[_files objectAtIndex:idx] removeObserver:self forKeyPath:@"collapsed"];
        [_files removeObjectAtIndex:idx];
    }];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    return [indexes count];
}

- (NSIndexSet *)indexesOfFilesToRemoveForNode:(Node *)node
{
    ECASSERT([_files containsObject:node]);
    NSOrderedSet *children = [node children];
    if ([children count])
    {
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        for (Node *childNode in [node children])
        {
            ECASSERT([_files containsObject:childNode]);
            if (!childNode.collapsed)
                [indexes addIndexes:[self indexesOfFilesToRemoveForNode:childNode]];
            [indexes addIndex:[_files indexOfObject:childNode]];
        }
        return indexes;
    }
    return nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"collapsed"])
    if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue])
        [self removeFilesForNode:object];
    else
        [self addFilesForNode:object];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)viewDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectChangedNotification:) name:ClientCurrentProjectChangedNotification object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeAllFiles];
}

- (void)handleProjectChangedNotification:(NSNotification *)notification
{
    [self removeAllFiles];
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.files count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DefaultIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultIdentifier];
    }
    cell.textLabel.text = [[self.files objectAtIndex:indexPath.row] name];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [[self.files objectAtIndex:indexPath.row] depth];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Node *node = [self.files objectAtIndex:indexPath.row];
    if ([node isKindOfClass:[File class]])
        [Client sharedClient].currentFile = (File *)node;
    else
        node.collapsed = !node.collapsed;
}

@end
