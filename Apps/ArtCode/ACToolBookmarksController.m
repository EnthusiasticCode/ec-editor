//
//  ACToolBookmarksController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 03/07/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ACToolBookmarksController.h"
#import "AppStyle.h"

@implementation ACToolBookmarksController {
    UIImage *starImage;
    UIImage *noteImage;
}

@synthesize tableView;
@synthesize filterContainerView;
@synthesize addButton;
@synthesize filterTextField;

//- (void)didReceiveMemoryWarning
//{
//    // Releases the view if it doesn't have a superview.
//    [super didReceiveMemoryWarning];
//    
//    // Release any cached data, images, etc that aren't in use.
//}

#pragma mark - View lifecycle
- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect toFrame = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    UIViewAnimationCurve animationCurve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double animationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    CGRect filterContainerFrame = filterContainerView.frame;
    if(fabsf(toFrame.size.height) < 264.)
    {
        filterContainerFrame.origin.y = self.view.bounds.size.height - filterContainerFrame.size.height;
    }
    else
    {
        filterContainerFrame.origin.y = toFrame.origin.y - filterContainerFrame.size.height;
    }
    
    CGRect tableViewFrame = tableView.frame;
    tableViewFrame.size.height = filterContainerFrame.origin.y - tableViewFrame.origin.y;
    
    [UIView animateWithDuration:animationDuration delay:0 options:animationCurve << 16 animations:^(void) {
        filterContainerView.frame = filterContainerFrame;
        tableView.frame = tableViewFrame;
    } completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Keyboard frame change management
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    // Load cell's images
    starImage = [UIImage imageNamed:@"toolBookmarksStar.png"];
    noteImage = [UIImage imageNamed:@"toolBookmarksNote.png"];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    tableView.delegate = self;
    tableView.dataSource = self;
    
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [UIColor styleBackgroundColor];
    
    // TODO Write hints in this view
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 10)];
    tableView.tableFooterView = footerView;
    
    // Initializing filters
    CALayer *layer = filterContainerView.layer;
    layer.borderColor = [UIColor styleBackgroundColor].CGColor;
    layer.borderWidth = 1;
    
    // Add button
    [addButton setImage:[UIImage styleAddImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil] forState:UIControlStateNormal];
    layer = addButton.layer;
    layer.borderColor = [UIColor styleBackgroundColor].CGColor;
    layer.borderWidth = 1;
    
    // Filter text field
    filterTextField.rightView = [[UIImageView alloc] initWithImage:[UIImage styleSearchIconWithColor:[UIColor styleBackgroundColor] shadowColor:nil]];
    filterTextField.rightViewMode = UITextFieldViewModeUnlessEditing;
}

- (void)viewDidUnload
{
    [self setFilterContainerView:nil];
    [self setAddButton:nil];
    [self setFilterTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        static UIImage *disclosureImage = nil;
        if (!disclosureImage)
            disclosureImage = [UIImage styleTableDisclosureImageWithColor:[UIColor styleBackgroundColor] shadowColor:nil];
        cell.accessoryView = [[UIImageView alloc] initWithImage:disclosureImage];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.textLabel.textColor = [UIColor styleBackgroundColor];
        
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = [UIColor styleHighlightColor];
    }
    
    NSUInteger idx = [indexPath indexAtPosition:1];
    cell.imageView.image = idx % 2 ? noteImage : starImage;
    
    cell.textLabel.text = @"prova";
    cell.detailTextLabel.text = @"subtext";
    
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

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}

@end
