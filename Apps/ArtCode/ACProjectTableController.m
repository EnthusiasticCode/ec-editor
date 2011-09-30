//
//  ACProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectTableController.h"
#import "AppStyle.h"
#import "ACEditableTableCell.h"
#import "ACColorSelectionControl.h"

#import "ACURL.h"
#import "ArtCodeAppDelegate.h"
#import "ACApplication.h"
#import "ACTab.h"
#import "ACProject.h"
#import "ACNavigationController.h"

#import "ACNewProjectPopoverController.h"

#import <ECUIKit/ECPopoverController.h>

#import <ECUIKit/ECBezelAlert.h>

#define STATIC_OBJECT(typ, nam, init) static typ *nam = nil; if (!nam) nam = init

static void * ACStateProjectsObservingContext;

@interface ACProjectTableController () {
    ECPopoverController *_popover;
}

- (void)deleteTableRow:(id)sender;
@end

@implementation ACProjectTableController {
    ECPopoverController *popoverLabelColorController;
}

@synthesize application = _application;
@synthesize tab = _tab;

- (void)setApplication:(ACApplication *)application
{
    if (application == _application)
        return;
    [self willChangeValueForKey:@"application"];
    [_application removeObserver:self forKeyPath:@"projects" context:ACStateProjectsObservingContext];
    _application = application;
    [_application addObserver:self forKeyPath:@"projects" options:NSKeyValueObservingOptionNew context:ACStateProjectsObservingContext];
    [self didChangeValueForKey:@"application"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 55;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
    
    self.tableView.tableFooterView = [UIView new];
    
    [self.application addObserver:self forKeyPath:@"projectURLs" options:NSKeyValueObservingOptionNew context:ACStateProjectsObservingContext];
    
    [self setEditing:NO animated:NO];
}

- (void)viewDidUnload
{
    [self.application removeObserver:self forKeyPath:@"projectURLs" context:ACStateProjectsObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != ACStateProjectsObservingContext)
        return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    [self.tableView reloadData];
    [_popover dismissPopoverAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    popoverLabelColorController = nil;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // Prepare tips image view
    UIView *newView = nil;
    if ([self tableView:self.tableView numberOfRowsInSection:0] == 0)
    {
        if (!editing)
        {
            newView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectBrowserTipsEmpty"]];
            CGRect frame = newView.frame;
            frame.origin.x += 37;
            newView.frame = frame;
        }
    }
    else if (editing)
    {
        newView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"projectBrowserTipsPopulatedEdit"]];
        CGRect frame = newView.frame;
        frame.origin.x += 22;
        newView.frame = frame;
    }
    
    // Animate new tip in place with crossfade with one already present
    NSArray *oldViews = self.tableView.tableFooterView.subviews;
    [self.tableView.tableFooterView addSubview:newView];
    newView.alpha = 0;
    [UIView animateWithDuration:STYLE_ANIMATION_DURATION animations:^{
        for (UIView *currentViews in oldViews) {
            currentViews.alpha = 0;
        }
        newView.alpha = 1;
    } completion:^(BOOL finished) {
        [oldViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }];
    
#warning TODO remove 'create new project' tip after creating the first project
}

#pragma mark - Tool Target Protocol

@synthesize toolButton;

+ (id)newNavigationTargetController
{
    return [ACProjectTableController new];
}

- (BOOL)enableTabBar
{
    return YES;
}

- (BOOL)enableToolPanelControllerWithIdentifier:(NSString *)toolControllerIdentifier
{
    return NO;
}

- (void)applyFilter:(NSString *)filter
{
    // TODO filter
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
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewProjectPopover" bundle:[NSBundle mainBundle]];
        ACNewProjectPopoverController *popoverViewController = (ACNewProjectPopoverController *)[storyboard instantiateInitialViewController];
        popoverViewController.application = self.application;
        _popover = [[ECPopoverController alloc] initWithContentViewController:popoverViewController];
    }
    [_popover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Colored icons

- (UIImage *)projectIconWithColor:(UIColor *)color
{
    // Icons cache
    STATIC_OBJECT(NSCache, iconCache, [NSCache new]);
    
    // Cell icon
    UIImage *cellIcon = [iconCache objectForKey:color];
    if (!cellIcon)
        cellIcon = [UIImage styleProjectImageWithSize:CGSizeMake(32, 33) labelColor:color];
    
    return cellIcon;
}

#pragma mark - Color label selection methods

- (void)colorSelectionAction:(ACColorSelectionControl *)sender
{
    // TODO change way of retrieving cell?
    
    ACEditableTableCell *cell = (ACEditableTableCell *)sender.userInfo;
    [cell.iconButton setImage:[self projectIconWithColor:sender.selectedColor] forState:UIControlStateNormal];
    
    [popoverLabelColorController dismissPopoverAnimated:YES];
    
    // TODO here change persisten color with sender.selectedColor
}


- (void)labelColorAction:(id)sender
{
    if (!popoverLabelColorController)
    {
        ACColorSelectionControl *colorControl = [ACColorSelectionControl new];
        colorControl.colorCellsMargin = 2;
        colorControl.columns = 3;
        colorControl.rows = 2;
        colorControl.colors = [NSArray arrayWithObjects:
                               [UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1], 
                               [UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1], 
                               [UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
                               [UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
                               [UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1],
                               [UIColor styleForegroundColor], nil];
        [colorControl addTarget:self action:@selector(colorSelectionAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIViewController *viewController = [UIViewController new];
        viewController.contentSizeForViewInPopover = CGSizeMake(145, 90);
        viewController.view = colorControl;
        
        popoverLabelColorController = [[ECPopoverController alloc] initWithContentViewController:viewController];
    }
    
    // Retrieve cell
    id cell = sender;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]])
        cell = [cell superview];
    [(ACColorSelectionControl *)popoverLabelColorController.contentViewController.view setUserInfo:cell];
    
    [popoverLabelColorController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
}

#pragma mark - Table view functionality

- (void)deleteTableRow:(id)sender
{
    NSInteger rowIndex = [(UIControl *)sender tag];
    ECASSERT(rowIndex >= 0);
    [self.tableView beginUpdates];
    [self.application deleteObjectWithURL:[[self.application.projects objectAtIndex:rowIndex] ACURL]];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:rowIndex inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.text = [[self.application.projects objectAtIndex:textField.tag] name];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![textField.text length])
        return NO;
    [self.application moveObjectWithURL:[[self.application.projects objectAtIndex:textField.tag] ACURL] toURL:[self.application ACURLForProjectWithName:textField.text]];
    [[self.application.projects objectAtIndex:textField.tag] setName:textField.text];
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.application.projects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    // Backgrounds images
    STATIC_OBJECT(UIImage, cellBackgroundImage, [UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    STATIC_OBJECT(UIImage, cellHighlightedImage, [UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    
    // Create cell
    static NSString *CellIdentifier = @"ProjectCell";
    ACEditableTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[ACEditableTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.backgroundView = [[UIImageView alloc] initWithImage:cellBackgroundImage];
        cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:cellHighlightedImage];
        
        // Icon button default setup
        [cell.iconButton addTarget:self action:@selector(labelColorAction:) forControlEvents:UIControlEventTouchUpInside];
        
        // Text field default setup
        STATIC_OBJECT(UIFont, font, [UIFont styleFontWithSize:18]);
        cell.textField.font = font;
        cell.textField.delegate = self;
        
        // Accessory default setup
        STATIC_OBJECT(UIImage, disclosureImage, [UIImage styleTableDisclosureImageWithColor:[UIColor styleForegroundColor] shadowColor:[UIColor whiteColor]]);
        cell.accessoryView = [[UIImageView alloc] initWithImage:disclosureImage];
        
        // Layout
        cell.contentInsets = UIEdgeInsetsMake(3, 10, 0, 10);
        cell.editingContentInsets = UIEdgeInsetsMake(4, 8, 4, 7);
        cell.iconButton.bounds = CGRectMake(0, 0, 32, 33);
        cell.customDelete = YES;
        [cell.customDeleteButton addTarget:self action:@selector(deleteTableRow:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Setup project icon
    // TODO use project color
    [cell.iconButton setImage:[self projectIconWithColor:[UIColor styleForegroundColor]] forState:UIControlStateNormal];
    
    // Setup project title
    [cell.textField setText:[[self.application.projects objectAtIndex:indexPath.row] name]];
    
    // Setup tags for callbacks
    [cell.customDeleteButton setTag:indexPath.row];
    [cell.textField setTag:indexPath.row];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove 'slide to delete' on cells.
    return self.isEditing;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [self.application moveProjectsAtIndexes:[NSIndexSet indexSetWithIndex:sourceIndexPath.row] toIndex:destinationIndexPath.row];
}

// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [[[ACState sharedState].projects objectAtIndex:indexPath.row] delete];
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    }   
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
//}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
        return;
    [self.tab pushURL:[[self.application.projects objectAtIndex:indexPath.row] ACURL]];
}

@end
