//
//  RemotesListController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 19/02/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RemotesListController.h"
#import "ArtCodeTab.h"
#import "ACProject.h"
#import "ACProjectRemote.h"

#import "NSArray+ScoreForAbbreviation.h"
#import "HighlightTableViewCell.h"
#import "ShapePopoverBackgroundView.h"
#import "NewRemoteViewController.h"
#import "UIViewController+Utilities.h"

@class SingleTabController, TopBarToolbar;

static void *_currentProjectRemotesContext;

@interface RemotesListController ()

@property (nonatomic, strong) ACProject *currentProject;

- (void)_toolAddAction:(id)sender;
- (void)_toolDeleteAction:(id)sender;

@end

@implementation RemotesListController {
    NSArray *_filteredRemotes;
    NSArray *_filteredRemotesHitMasks;
    
    UIPopoverController *_toolAddPopover;
}

- (id)init
{
    self = [super initWithTitle:@"Remotes" searchBarStaticOnTop:NO];
    if (!self)
        return nil;
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &_currentProjectRemotesContext)
    {
        [self invalidateFilteredItems];
        [self.tableView reloadData];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Properties

@synthesize currentProject;

- (void)setCurrentProject:(ACProject *)value
{
    if (value == currentProject)
        return;
    
    [currentProject removeObserver:self forKeyPath:@"remotes" context:&_currentProjectRemotesContext];
    currentProject = value;
    [currentProject addObserver:self forKeyPath:@"remotes" options:NSKeyValueObservingOptionNew context:&_currentProjectRemotesContext];
}

- (NSArray *)filteredItems
{ 
    if (!_filteredRemotes)
    {
        if ([self.searchBar.text length] == 0)
        {
            _filteredRemotes = self.artCodeTab.currentProject.remotes;
            _filteredRemotesHitMasks = nil;
        }
        else
        {
            NSArray *hitMasks = nil;
            _filteredRemotes = [self.artCodeTab.currentProject.remotes sortedArrayUsingScoreForAbbreviation:self.searchBar.text resultHitMasks:&hitMasks extrapolateTargetStringBlock:^NSString *(ACProjectRemote *element) {
                return element.name;
            }];
            _filteredRemotesHitMasks = hitMasks;
        }
    }
    return _filteredRemotes;
}

- (void)invalidateFilteredItems
{
    _filteredRemotes = nil;
    _filteredRemotesHitMasks = nil;
    [super invalidateFilteredItems];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];

    self.toolNormalItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolAddAction:)]];
    
    self.toolEditItems = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolDeleteAction:)]];
    
    // Load the bottom toolbar
    [[NSBundle mainBundle] loadNibNamed:@"BrowserControllerBottomBar" owner:self options:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.searchBar.placeholder = @"Filter remotes";
}

- (void)viewDidUnload
{
    _toolAddPopover = nil;
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.currentProject = self.artCodeTab.currentProject;
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.currentProject = nil;
    [super viewWillDisappear:animated];
}

#pragma mark - Single tab content controller protocol methods

- (BOOL)singleTabController:(SingleTabController *)singleTabController shouldEnableTitleControlForDefaultToolbar:(TopBarToolbar *)toolbar
{
    return NO;
}

#pragma mark - Table view datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HighlightTableViewCell *cell = (HighlightTableViewCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    ACProjectRemote *remote = [self.filteredItems objectAtIndex:indexPath.row];
    cell.textLabel.text = remote.name;
    cell.textLabelHighlightedCharacters = _filteredRemotesHitMasks ? [_filteredRemotesHitMasks objectAtIndex:indexPath.row] : nil;
    cell.detailTextLabel.text = [[remote URL] absoluteString];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isEditing)
    {
        [self.artCodeTab pushURL:[[self.filteredItems objectAtIndex:indexPath.row] URL]];
    }
}

#pragma mark - Private methods

- (void)_toolAddAction:(id)sender
{
    if (!_toolAddPopover)
    {
        NewRemoteViewController *newRemote = [NewRemoteViewController new];
        newRemote.artCodeTab = self.artCodeTab;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:newRemote];
        [navigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
        _toolAddPopover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        _toolAddPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
        newRemote.presentingPopoverController = _toolAddPopover;
    }
    [_toolAddPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

@end
