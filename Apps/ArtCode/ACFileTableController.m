//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "AppStyle.h"
#import "ACEditableTableCell.h"

#import "ACToolFiltersView.h"

#import "ACNode.h"
#import "ACGroup.h"
#import "ACProject.h"
#import "ACProjectDocument.h"

@interface ACFileTableController ()
{
    NSArray *extensions;
    ACGroup *_displayedNode;
    UINavigationItem *_customNavigationItem;
    UIPopoverController *_popover;
}
@property (nonatomic, strong) NSMutableOrderedSet *nodes;

- (NSUInteger)addNodesForNode:(ACNode *)node;
- (NSUInteger)removeNodesForNode:(ACNode *)node;
- (NSIndexSet *)indexesOfNodesToRemoveForNode:(ACNode *)node;

- (void)addNewNode:(id)sender;

@end

@implementation ACFileTableController

@synthesize projectDocument = _projectDocument;
@synthesize editingToolsView;

@synthesize nodes = _nodes;

- (void)setNodes:(NSMutableOrderedSet *)nodes
{
    if (nodes == _nodes)
        return;
    [self willChangeValueForKey:@"nodes"];
    for (ACNode *node in _nodes)
        if ([node.nodeType isEqualToString:@"Group"])
            [node removeObserver:self forKeyPath:@"expanded"];
    _nodes = nodes;
    for (ACNode *node in _nodes)
        if ([node.nodeType isEqualToString:@"Group"])
            [node addObserver:self forKeyPath:@"expanded" options:NSKeyValueObservingOptionNew context:NULL];
    NSUInteger count = [_nodes count];
    for (NSUInteger i = 0; i < count; ++i)
    {
        ACNode *node = [_nodes objectAtIndex:i];
        NSUInteger addedNodesCount = [self addNodesForNode:node];
        i += addedNodesCount;
        count += addedNodesCount;
    }
    [self didChangeValueForKey:@"nodes"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"expanded"])
        if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue])
            [self removeNodesForNode:object];
        else
            [self addNodesForNode:object];
}

- (UINavigationItem *)navigationItem
{
    if (!_customNavigationItem)
    {
        _customNavigationItem = [super navigationItem];
        _customNavigationItem.rightBarButtonItem = self.editButtonItem;
    }
    return _customNavigationItem;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    // Creating the table view
    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
    self.tableView.separatorColor = [UIColor styleForegroundColor];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
    self.tableView.tableFooterView = footerView;
    
    extensions = [NSArray arrayWithObjects:@"h", @"m", @"hpp", @"cpp", @"mm", @"py", nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.projectDocument && self.projectDocument.documentState == UIDocumentStateClosed)
        [self.projectDocument openWithCompletionHandler:^(BOOL success) {
            if (!success)
                ECASSERT(NO); // TODO: error handling
            if (success)
                self.nodes = [NSMutableOrderedSet orderedSetWithOrderedSet:self.projectDocument.project.children];
        }];
    else
        self.nodes = [NSMutableOrderedSet orderedSetWithOrderedSet:self.projectDocument.project.children];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self.tableView setEditing:editing animated:animated];
    
    CGRect bounds = self.view.bounds;
    if (editing)
    {
        if (!editingToolsView)
        {
            
            editingToolsView = [ACToolFiltersView new];
            editingToolsView.backgroundColor = [UIColor styleForegroundColor];
            editingToolsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        }
        editingToolsView.frame = CGRectMake(0, bounds.size.height - 44, bounds.size.width, 44);
        bounds.size.height -= 44;
        if (!animated)
        {
            [self.view addSubview:editingToolsView];
            self.tableView.frame = bounds;
        }
        else
        {
            CGPoint center = editingToolsView.center;
            editingToolsView.center = CGPointMake(center.x, center.y + 44);
            [self.view addSubview:editingToolsView];
            [UIView animateWithDuration:0.10 animations:^(void) {
                editingToolsView.center = center;
                self.tableView.frame = bounds;
            }];
        }
    }
    else
    {
        if (!animated)
        {
            [editingToolsView removeFromSuperview];
            self.tableView.frame = self.view.bounds;
        }
        else
        {
            [UIView animateWithDuration:0.10 animations:^(void) {
                editingToolsView.frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
                self.tableView.frame = self.view.bounds;
            } completion:^(BOOL finished) {
                [editingToolsView removeFromSuperview];
            }];
        }
    }
}

- (BOOL)isEditing
{
    return self.tableView.isEditing;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_displayedNode.children count];
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    static NSString *GroupCellIdentifier = @"GroupCell";

    ACNode *cellNode = [_displayedNode.children objectAtIndex:indexPath.row];
    NSString *cellIdentifier = [[cellNode nodeType] isEqualToString:@"Group"] ? GroupCellIdentifier : FileCellIdentifier;
    ACEditableTableCell *cell = [tView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [[ACEditableTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.backgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
    }
    
    if (cellIdentifier == GroupCellIdentifier)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) color:[[cellNode.name pathExtension] isEqualToString:@"h"] ? [UIColor styleFileRedColor] : [UIColor styleFileBlueColor] text:[cellNode.name pathExtension]];
    [cell.textField setText:[cellNode name]];
    return cell;
}

#pragma mark - Private methods

- (NSUInteger)addNodesForNode:(ACNode *)node
{
    ECASSERT([self.nodes containsObject:node]);
    ECASSERT([node.nodeType isEqualToString:@"Group"]);
    NSUInteger addedFilesCount = 0;
    NSUInteger nodeIndex = [self.nodes indexOfObject:node];
    ECASSERT(nodeIndex != NSNotFound);
    NSOrderedSet *children = nil;
    if ([node.nodeType isEqualToString:@"Group"] && [(ACGroup *)node expanded])
        children = [(ACGroup *)node children];
    if ([children count])
    {
        [self.tableView beginUpdates];
        NSUInteger insertionIndex = nodeIndex + 1;
        for (ACNode *childNode in children)
        {
            [self.nodes insertObject:childNode atIndex:insertionIndex];
            [childNode addObserver:self forKeyPath:@"expanded" options:NSKeyValueObservingOptionNew context:NULL];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:insertionIndex inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
            insertionIndex++;
            addedFilesCount++;
            NSUInteger childAddedFilesCount = [self addNodesForNode:childNode];
            insertionIndex += childAddedFilesCount;
            addedFilesCount += childAddedFilesCount;
        }
        [self.tableView endUpdates];
    }
    return addedFilesCount;
}

- (NSUInteger)removeNodesForNode:(ACNode *)node
{
    ECASSERT([self.nodes containsObject:node]);
    ECASSERT([node.nodeType isEqualToString:@"Group"]);
    NSIndexSet *indexes = [self indexesOfNodesToRemoveForNode:node];
    if (![indexes count])
        return 0;
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[indexes count]];
    [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
        [[self.nodes objectAtIndex:idx] removeObserver:self forKeyPath:@"expanded"];
        [self.nodes removeObjectAtIndex:idx];
    }];
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    [self.tableView endUpdates];
    return [indexes count];
}

- (NSIndexSet *)indexesOfNodesToRemoveForNode:(ACNode *)node
{
    ECASSERT([self.nodes containsObject:node]);
    ECASSERT([node.nodeType isEqualToString:@"Group"]);
    NSOrderedSet *children = nil;
    if ([node.nodeType isEqualToString:@"Group"])
        children = [(ACGroup *)node children];
    if ([children count])
    {
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        for (ACNode *childNode in children)
        {
            ECASSERT([self.nodes containsObject:childNode]);
            if ([childNode.nodeType isEqualToString:@"Group"] && [(ACGroup *)childNode expanded])
                [indexes addIndexes:[self indexesOfNodesToRemoveForNode:childNode]];
            [indexes addIndex:[self.nodes indexOfObject:childNode]];
        }
        return indexes;
    }
    return nil;
}

@end
