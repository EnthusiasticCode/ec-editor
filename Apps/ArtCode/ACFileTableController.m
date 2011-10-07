//
//  ACFileTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 01/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACFileTableController.h"
#import "AppStyle.h"
#import "ACNavigationController.h"
#import "ACEditableTableCell.h"
#import "ACNewFilePopoverController.h"
#import <ECFoundation/ECDirectoryPresenter.h>

#import "ACToolFiltersView.h"
#import <ECUIKit/ECPopoverController.h>

#import "ACTab.h"

static void * directoryPresenterFileURLsObservingContext;

@interface ACFileTableController () {
    ECPopoverController *_popover;
}
@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;
@end

@implementation ACFileTableController {
    NSArray *extensions;
}

@synthesize tableView, editingToolsView;
@synthesize directory = _directory;
@synthesize tab = _tab;
@synthesize directoryPresenter = _directoryPresenter;

@synthesize toolButton;

- (void)setDirectory:(NSURL *)directory
{
    if (directory == _directory)
        return;
    [self willChangeValueForKey:@"directory"];
    _directory = directory;
    self.directoryPresenter.directory = _directory;
    [self didChangeValueForKey:@"directory"];
}

- (void)setDirectoryPresenter:(ECDirectoryPresenter *)directoryPresenter
{
    if (directoryPresenter == _directoryPresenter)
        return;
    [self willChangeValueForKey:@"directoryPresenter"];
    [_directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&directoryPresenterFileURLsObservingContext];
    _directoryPresenter = directoryPresenter;
    [_directoryPresenter addObserver:self forKeyPath:@"fileURLs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&directoryPresenterFileURLsObservingContext];
    [self didChangeValueForKey:@"directoryPresenter"];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &directoryPresenterFileURLsObservingContext)
    {
        // TODO: add / delete / move table rows instead of reloading all once NSFilePresenter actually works
        [self.tableView reloadData];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];

    // Creating the table view
    if (!tableView)
    {
        tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tableView.dataSource = self;
        tableView.delegate = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:tableView];
        
        tableView.backgroundColor = [UIColor styleBackgroundColor];
        tableView.separatorColor = [UIColor styleForegroundColor];
        tableView.allowsMultipleSelectionDuringEditing = YES;
    }
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 0)];
    tableView.tableFooterView = footerView;
    
    extensions = [NSArray arrayWithObjects:@"h", @"m", @"hpp", @"cpp", @"mm", @"py", nil];
    
    [self setEditing:NO animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    tableView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.directoryPresenter = [[ECDirectoryPresenter alloc] init];
    self.directoryPresenter.directory = self.directory;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.directoryPresenter = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [tableView setEditing:editing animated:animated];
    
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
            tableView.frame = bounds;
        }
        else
        {
            CGPoint center = editingToolsView.center;
            editingToolsView.center = CGPointMake(center.x, center.y + 44);
            [self.view addSubview:editingToolsView];
            [UIView animateWithDuration:0.10 animations:^(void) {
                editingToolsView.center = center;
                tableView.frame = bounds;
            }];
        }
    }
    else
    {
        if (!animated)
        {
            [editingToolsView removeFromSuperview];
            tableView.frame = self.view.bounds;
        }
        else
        {
            [UIView animateWithDuration:0.10 animations:^(void) {
                editingToolsView.frame = CGRectMake(0, bounds.size.height, bounds.size.width, 44);
                tableView.frame = self.view.bounds;
            } completion:^(BOOL finished) {
                [editingToolsView removeFromSuperview];
            }];
        }
    }
}

- (BOOL)isEditing
{
    return tableView.isEditing;
}

#pragma mark - Tool Target Methods

+ (id)newNavigationTargetController
{
    return [[ACFileTableController alloc] initWithNibName:@"ACFileTableController" bundle:nil];
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return YES;
}

- (void)setScrollToRequireGestureRecognizerToFail:(UIGestureRecognizer *)recognizer
{
    [tableView.panGestureRecognizer requireGestureRecognizerToFail:recognizer];
}

- (UIButton *)toolButton
{
    if (!toolButton)
    {
        toolButton = [UIButton new];
        [toolButton addTarget:self action:@selector(toolButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [toolButton setImage:[UIImage styleAddImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]] forState:UIControlStateNormal];
        toolButton.adjustsImageWhenHighlighted = NO;
    }
    return toolButton;
}

#pragma mark -

- (void)toolButtonAction:(id)sender
{
    // Removing the lazy loading could cause the old popover to be overwritten by the new one causing a dealloc while popover is visible
    if (!_popover)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewFilePopover" bundle:[NSBundle mainBundle]];
        ACNewFilePopoverController *popoverViewController = (ACNewFilePopoverController *)[storyboard instantiateInitialViewController];
//        popoverViewController.group = self.group;
        _popover = [[ECPopoverController alloc] initWithContentViewController:popoverViewController];
    }
    [_popover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.directoryPresenter.fileURLs count];
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    
    ACEditableTableCell *cell = [tView dequeueReusableCellWithIdentifier:FileCellIdentifier];
    if (cell == nil)
    {
        cell = [[ACEditableTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FileCellIdentifier];
        cell.backgroundView = nil;
        cell.indentationWidth = 38;
        
        UIView *selectionView = [UIView new];
        selectionView.backgroundColor = [UIColor styleHighlightColor];
        cell.selectedBackgroundView = selectionView;
    }
    
    // Configure the cell...
//    NSUInteger idx = [indexPath indexAtPosition:1];
//    cell.indentationLevel = 0;
//    if (idx < 2)
//    {
//        cell.textField.text = @"File";
//        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
//                                                             color:idx % 2 ? [UIColor styleFileBlueColor] : [UIColor styleFileRedColor] 
//                                                              text:[extensions objectAtIndex:idx]];
//    }
//    else if (idx == 2)
//    {
//        cell.textField.text = @"Group";
//        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
//    }
//    else 
//    {
//        cell.textField.text = @"File";
//        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
//                                                             color:idx % 2 ? [UIColor styleFileBlueColor] : [UIColor styleFileRedColor] 
//                                                              text:[extensions objectAtIndex:idx - 1]];
//        cell.indentationLevel = 1;
//        [cell setColor:[UIColor colorWithWhite:0.8 alpha:1] forIndentationLevel:0 animated:YES];
//    }
//    ACNode *cellNode = [self.group.children objectAtIndex:indexPath.row];
//    if (![cellNode.name pathExtension])
//        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
//    else
//        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
//                                                             color:[[cellNode.name pathExtension] isEqualToString:@"h"] ? [UIColor styleFileRedColor] : [UIColor styleFileBlueColor]
//                                                              text:[cellNode.name pathExtension]];
    cell.textField.text = [[self.directoryPresenter.fileURLs objectAtIndex:indexPath.row] lastPathComponent];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
        return;
    [self.tab pushURL:[self.directoryPresenter.fileURLs objectAtIndex:indexPath.row]];
}

@end
