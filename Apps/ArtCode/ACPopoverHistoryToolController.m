//
//  ACNavigationHistoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACPopoverHistoryToolController.h"
#import "AppStyle.h"
#import "ACTab.h"

static void * ACPopoverHistoryToolControllerTabCurrentHistoryPositionObserving;
static void * ACPopoverHistoryToolControllerTabHistoryItemsObserving;

#define SECTION_BACK_TO_PROJECTS 1
#define SECTION_HISTORY_URLS 0

@interface ACPopoverHistoryToolController ()
- (NSUInteger)historyIndexForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)currentHistoryPositionIsAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation ACPopoverHistoryToolController

@synthesize tab = _tab;

- (void)setTab:(ACTab *)tab
{
    if (tab == _tab)
        return;
    [_tab removeObserver:self forKeyPath:@"currentHistoryPosition" context:ACPopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab removeObserver:self forKeyPath:@"historyItems" context:ACPopoverHistoryToolControllerTabHistoryItemsObserving];
    _tab = tab;
    [_tab addObserver:self forKeyPath:@"currentHistoryPosition" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:ACPopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab addObserver:self forKeyPath:@"historyItems" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:ACPopoverHistoryToolControllerTabHistoryItemsObserving];
}

- (void)dealloc
{
    [_tab removeObserver:self forKeyPath:@"currentHistoryPosition" context:ACPopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab removeObserver:self forKeyPath:@"historyItems" context:ACPopoverHistoryToolControllerTabHistoryItemsObserving];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == ACPopoverHistoryToolControllerTabHistoryItemsObserving)
    {
        [self.tableView reloadData];
    }
    else if (context == ACPopoverHistoryToolControllerTabCurrentHistoryPositionObserving)
    {
        // TODO: different formatting for current history position, update without reloading on history position change
        // NOTE: doesn't seem to be needed as changing the current history position triggers the history items observing as well
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
    self.tableView.separatorColor = [UIColor styleForegroundColor];
    // TODO make this a button to go back to projects?
    self.tableView.tableFooterView = [UIView new];
}

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
    return section == SECTION_HISTORY_URLS ? [self.tab.historyItems count] : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSUInteger section = [indexPath indexAtPosition:0];
    
    // Configure the 'back to projects' cell
    if (section == SECTION_BACK_TO_PROJECTS)
    {
        // TODO localize
        cell.textLabel.text = @"Back to projects";
    }
    else
    {
        cell.textLabel.text = [[[self.tab.historyItems objectAtIndex:[self historyIndexForIndexPath:indexPath]] URL] path];
        if ([self currentHistoryPositionIsAtIndexPath:indexPath])
            cell.imageView.image = [UIImage imageNamed:@"toolPanelBookmarksToolSelectedImage.png"];
        else
            cell.imageView.image = nil;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (NSUInteger)historyIndexForIndexPath:(NSIndexPath *)indexPath
{
    return [self.tab.historyItems count] - 1 - indexPath.row;
}

- (BOOL)currentHistoryPositionIsAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tab.historyItems count] - 1 - self.tab.currentHistoryPosition == indexPath.row;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tab.currentHistoryPosition = [self historyIndexForIndexPath:indexPath];
}

@end
