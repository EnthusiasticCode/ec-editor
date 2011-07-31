//
//  ACNavigationHistoryController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACPopoverHistoryToolController.h"
#import "AppStyle.h"

#define SECTION_BACK_TO_PROJECTS 1
#define SECTION_HISTORY_URLS 0

@implementation ACPopoverHistoryToolController {
    NSArray *historyURLs;
    NSUInteger historyPoint;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // TODO release this?
    historyURLs = nil;
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    historyURLs = nil;
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
    return section == SECTION_HISTORY_URLS ? [historyURLs count] : 1;
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
        NSUInteger historyIndex = [indexPath indexAtPosition:1];
        cell.textLabel.text = [[historyURLs objectAtIndex:historyIndex] path];
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

#pragma mark - Public Methods

- (void)setHistoryURLs:(NSArray *)urls hisoryPointIndex:(NSUInteger)index
{
    ECASSERT(urls != nil);
    ECASSERT(index < [urls count]);
    
    // TODO filter out urls with nil path
    
    historyURLs = urls;
    historyPoint = index;
    
    [self.tableView reloadData];
}

@end
