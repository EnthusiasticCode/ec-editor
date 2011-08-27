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

#import "ACToolFiltersView.h"

#import "ACState.h"

@implementation ACFileTableController {
    NSArray *extensions;
    id<ACStateNode> _displayedNode;
}

@synthesize tableView, editingToolsView;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    tableView = nil;
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
    return [ACFileTableController new];
}

- (void)openURL:(NSURL *)url
{
    _displayedNode = [[ACState localState] nodeForURL:url];
    [self.tableView reloadData];
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return YES;
}

- (void)applyFilter:(NSString *)filter
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    return 7;
    return [_displayedNode.children count];
}

- (UITableViewCell *)tableView:(UITableView *)tView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *FileCellIdentifier = @"FileCell";
    
    ACEditableTableCell *cell = [tView dequeueReusableCellWithIdentifier:FileCellIdentifier];
    if (cell == nil)
    {
        cell = [[ACEditableTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FileCellIdentifier];
        cell.backgroundView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.indentationWidth = 38;
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
    id<ACStateNode> cellNode = [_displayedNode.children objectAtIndex:indexPath.row];
    if (cellNode.nodeType == ACStateNodeTypeFolder || cellNode.nodeType == ACStateNodeTypeGroup)
        cell.imageView.image = [UIImage styleGroupImageWithSize:CGSizeMake(32, 32)];
    else
        cell.imageView.image = [UIImage styleDocumentImageWithSize:CGSizeMake(32, 32) 
                                                             color:[[cellNode.name pathExtension] isEqualToString:@"h"] ? [UIColor styleFileRedColor] : [UIColor styleFileBlueColor]
                                                              text:[cellNode.name pathExtension]];
    [cell.textField setText:[cellNode name]];
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
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
    if (self.isEditing)
        return;
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    // TODO if used in a popover from the jump bar should just change its own url
    
    [self.ACNavigationController pushURL:[[_displayedNode.children objectAtIndex:indexPath.row] URL]];
}

@end
