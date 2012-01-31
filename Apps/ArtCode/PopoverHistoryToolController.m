//
//  NavigationHistoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PopoverHistoryToolController.h"
#import "AppStyle.h"
#import "ArtCodeTab.h"

static void * PopoverHistoryToolControllerTabCurrentHistoryPositionObserving;
static void * PopoverHistoryToolControllerTabHistoryItemsObserving;

#define SECTION_BACK_TO_PROJECTS 1
#define SECTION_HISTORY_URLS 0

@interface PopoverHistoryToolController ()
- (NSUInteger)historyIndexForIndexPath:(NSIndexPath *)indexPath;
- (BOOL)currentHistoryPositionIsAtIndexPath:(NSIndexPath *)indexPath;
@end

@implementation PopoverHistoryToolController

@synthesize tab = _tab;

- (void)setTab:(ArtCodeTab *)tab
{
    if (tab == _tab)
        return;
    [_tab removeObserver:self forKeyPath:@"currentHistoryPosition" context:&PopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab removeObserver:self forKeyPath:@"historyURLs" context:&PopoverHistoryToolControllerTabHistoryItemsObserving];
    _tab = tab;
    [_tab addObserver:self forKeyPath:@"currentHistoryPosition" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&PopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab addObserver:self forKeyPath:@"historyURLs" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:&PopoverHistoryToolControllerTabHistoryItemsObserving];
}

- (void)dealloc
{
    [_tab removeObserver:self forKeyPath:@"currentHistoryPosition" context:&PopoverHistoryToolControllerTabCurrentHistoryPositionObserving];
    [_tab removeObserver:self forKeyPath:@"historyURLs" context:&PopoverHistoryToolControllerTabHistoryItemsObserving];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &PopoverHistoryToolControllerTabHistoryItemsObserving)
    {
        [self.tableView reloadData];
    }
    else if (context == &PopoverHistoryToolControllerTabCurrentHistoryPositionObserving)
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
    return section == SECTION_HISTORY_URLS ? [self.tab.historyURLs count] : 1;
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
        cell.textLabel.text = [[[self.tab.historyURLs objectAtIndex:[self historyIndexForIndexPath:indexPath]] URL] path];
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
    return [self.tab.historyURLs count] - 1 - indexPath.row;
}

- (BOOL)currentHistoryPositionIsAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.tab.historyURLs count] - 1 - self.tab.currentHistoryPosition == indexPath.row;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.tab.currentHistoryPosition = [self historyIndexForIndexPath:indexPath];
}

@end
