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

#import "ArtCodeAppDelegate.h"
#import "ACApplication.h"
#import "ACTab.h"
#import "ACNavigationController.h"

#import "ACNewProjectPopoverController.h"

#import <ECFoundation/ECDirectoryPresenter.h>

#import <ECUIKit/ECPopoverController.h>

#import <ECUIKit/ECBezelAlert.h>

static void * directoryPresenterFileURLsObservingContext;

#define STATIC_OBJECT(typ, nam, init) static typ *nam = nil; if (!nam) nam = init

@interface ACProjectTableController ()
{
    ECPopoverController *popoverLabelColorController;
    ECPopoverController *_popover;
}
@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;
- (void)deleteTableRow:(id)sender;
@end

@implementation ACProjectTableController

#pragma mark - Properties

@synthesize projectsDirectory = _projectsDirectory;
@synthesize tab = _tab;
@synthesize directoryPresenter = _directoryPresenter;

- (void)setProjectsDirectory:(NSURL *)projectsDirectory
{
    if (projectsDirectory == _projectsDirectory)
        return;
    [self willChangeValueForKey:@"projectsDirectory"];
    _projectsDirectory = projectsDirectory;
    self.directoryPresenter.directory = _projectsDirectory;
    [self didChangeValueForKey:@"projectsDirectory"];
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

#pragma mark - General methods

- (void)dealloc
{
    [self.directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&directoryPresenterFileURLsObservingContext];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = 55;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor styleBackgroundColor];
    
    self.tableView.tableFooterView = [UIView new];
    
    [self setEditing:NO animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.directoryPresenter = [[ECDirectoryPresenter alloc] init];
    self.directoryPresenter.directory = self.projectsDirectory;
}

- (void)viewDidDisappear:(BOOL)animated
{
    self.directoryPresenter = nil;
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
        popoverViewController.projectsDirectory = self.projectsDirectory;
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
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:rowIndex];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtURL:newURL error:NULL];
    }];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.text = [[self.directoryPresenter.fileURLs objectAtIndex:textField.tag] lastPathComponent];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![textField.text length])
        return NO;
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:textField.tag];
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForMoving error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager moveItemAtURL:newURL toURL:[[newURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:textField.text] error:NULL];
    }];
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
    return [self.directoryPresenter.fileURLs count];
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
    [cell.textField setText:[[self.directoryPresenter.fileURLs objectAtIndex:indexPath.row] lastPathComponent]];
    
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
        return;
//    [self.tab pushURL:[[self.application.projects objectAtIndex:indexPath.row] fileURL]];
}

@end
