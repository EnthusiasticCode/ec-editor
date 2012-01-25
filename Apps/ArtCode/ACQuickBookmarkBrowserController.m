//
//  ACQuickBookmarkBrowserController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 25/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACQuickBookmarkBrowserController.h"
#import "ACQuickBrowsersContainerController.h"

#import <ECFoundation/NSTimer+block.h>

#import "ACTab.h"
#import "ACProject.h"

#import "AppStyle.h"
#import "ACHighlightTableViewCell.h"

@implementation ACQuickBookmarkBrowserController {
//    UISearchBar *_searchBar;
    UILabel *_infoLabel;
//    NSTimer *_filterDebounceTimer;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self)
        return nil;
    self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Bookmarks" image:nil tag:0];
    self.navigationItem.title = @"Bookmarks";
    return self;
}

#pragma mark - Properties

@synthesize tableView;

- (UITableView *)tableView
{
    if (!tableView)
    {
        tableView = [UITableView new];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return tableView;
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    
    CGRect bounds = self.view.bounds;
    
    // Add table view
    [self.view addSubview:self.tableView];
    self.tableView.frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    
    // Add table view footer view
//    _infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 50)];
//    _infoLabel.textAlignment = UITextAlignmentCenter;
//    _infoLabel.text = @"The project has no bookmarks";
//    self.tableView.tableFooterView = _infoLabel;
}


- (void)viewDidUnload
{
//    _infoLabel = nil;
    tableView = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
    return [self.quickBrowsersContainerController.tab.currentProject.bookmarks count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    ACHighlightTableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[ACHighlightTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.highlightLabel.highlightedBackgroundColor = [UIColor colorWithRed:225.0/255.0 green:220.0/255.0 blue:92.0/255.0 alpha:1];
    }
    
    ACProjectBookmark *bookmark = [self.quickBrowsersContainerController.tab.currentProject.bookmarks objectAtIndex:indexPath.row];
    
    NSUInteger bookmarkLine = [bookmark line];
    if (bookmarkLine != 0)
    {
        NSInteger fragmentLocation = [bookmark.bookmarkPath rangeOfString:@"#"].location;
        if (fragmentLocation != NSNotFound)
        {
            cell.textLabel.text = [[bookmark.bookmarkPath substringToIndex:fragmentLocation] stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
        else
        {
            cell.textLabel.text = [bookmark.bookmarkPath stringByAppendingFormat:@" - Line: %u", bookmarkLine];
        }
    }
    else
    {
        cell.textLabel.text = bookmark.bookmarkPath;
    }
    cell.detailTextLabel.text = bookmark.note;
    cell.imageView.image = [UIImage imageNamed:@"bookmarkTable_Icon"];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.quickBrowsersContainerController.popoverController dismissPopoverAnimated:YES];
    [self.quickBrowsersContainerController.tab pushURL:[[self.quickBrowsersContainerController.tab.currentProject.bookmarks objectAtIndex:indexPath.row] URL]];
}

@end
