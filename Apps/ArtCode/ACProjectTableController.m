//
//  ACProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectTableController.h"
#import "ACProjectTableCell.h"
#import "AppStyle.h"
#import "ACState.h"
#import "ACStateProject.h"
#import "ACNavigationController.h"

@implementation ACProjectTableController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 55;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
}

#pragma mark - ACNavigable Protocol

- (void)openURL:(NSURL *)url
{
    // TODO refresh projects
}

- (BOOL)shouldShowTabBar
{
    return YES;
}

- (BOOL)shouldShowToolPanelController:(ACToolController *)toolController
{
    return NO;
}

- (void)applyFilter:(NSString *)filter
{
    // TODO filter
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[ACState sharedState].allProjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO just for test, recreate all cells properly
    static NSString *CellIdentifier = @"ProjectCell";
    static UIImage *cellBackgroundImage = nil;
    static UIImage *cellHighlightedImage = nil;
    
    if (!cellBackgroundImage)
        cellBackgroundImage = [UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners];
    if (!cellHighlightedImage)
        cellHighlightedImage = [UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners];
    
    ACProjectTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[ACProjectTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundView = [[UIImageView alloc] initWithImage:cellBackgroundImage];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:cellHighlightedImage];
    }
    
    // Configure the cell...
    [cell.textLabel setText:[[[ACState sharedState].allProjects objectAtIndex:indexPath.row] name]];
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [[[ACState sharedState].allProjects objectAtIndex:sourceIndexPath.row] setIndex:destinationIndexPath.row];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [[ACState sharedState] deleteProjectWithName:[[[ACState sharedState].allProjects objectAtIndex:indexPath.row] name]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.ACNavigationController pushURL:[[[ACState sharedState].allProjects objectAtIndex:indexPath.row] URL] animated:YES];
}

@end
