//
//  ACProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectTableController.h"
#import "AppStyle.h"
#import "ACColorSelectionControl.h"

#import "ArtCodeAppDelegate.h"
#import "ACApplication.h"
#import "ACTab.h"
#import "ACProjectCell.h"
#import "ACProjectCellNormalView.h"
#import "ACProjectCellEditingView.h"

#import "ACNewProjectPopoverController.h"

#import <ECFoundation/ECDirectoryPresenter.h>

#import <ECUIKit/ECBezelAlert.h>

static void * directoryPresenterFileURLsObservingContext;

#define STATIC_OBJECT(typ, nam, init) static typ *nam = nil; if (!nam) nam = init

@interface ACProjectTableController () {
    UIPopoverController *_toolItemPopover;
    
    NSArray *_toolItemsNormal;
    NSArray *_toolItemsEditing;
}
@property (nonatomic, strong) GMGridView *gridView;
/// Represent a directory's contents.
@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;
- (void)_toolNormalAddAction:(id)sender;
- (void)_openButtonAction:(id)sender;
- (void)_deleteButtonAction:(id)sender;

@end

#pragma mark - Implementation
#pragma mark -

@implementation ACProjectTableController

#pragma mark - Properties

@synthesize tab = _tab;
@synthesize gridView = _gridView;
@synthesize projectsDirectory = _projectsDirectory, directoryPresenter = _directoryPresenter;

- (GMGridView *)gridView
{
    if (!_gridView)
    {
        _gridView = [[GMGridView alloc] init];
        _gridView.dataSource = self;
        _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _gridView;
}

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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    BOOL editingChanged = NO;
    if (editing != self.editing)
        editingChanged = YES;
    [super setEditing:editing animated:animated];
    
    if (!editingChanged)
        return;
    
    if (!editing)
        self.toolbarItems = _toolItemsNormal;
    else
        self.toolbarItems = _toolItemsEditing;
    
    if (editing)
        for (ACProjectCell *cell in [self.gridView visibleCells])
            cell.contentView = cell.editingView;
    else
        for (ACProjectCell *cell in [self.gridView visibleCells])
            cell.contentView = cell.normalView;
}

#pragma mark - Controller Methods

- (void)dealloc
{
    [self.directoryPresenter removeObserver:self forKeyPath:@"fileURLs" context:&directoryPresenterFileURLsObservingContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &directoryPresenterFileURLsObservingContext)
    {
        // TODO: add / delete / move table rows instead of reloading all once NSFilePresenter actually works
        [self.gridView reloadData];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - View lifecycle

- (void)loadView
{
    [super loadView];
    self.gridView.frame = self.view.bounds;
    [self.view addSubview:self.gridView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preparing tool items array changed in set editing
    _toolItemsNormal = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
    
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

#pragma mark - Tool Items Actions

- (void)_toolNormalAddAction:(id)sender
{
    // Removing the lazy loading could cause the old popover to be overwritten by the new one causing a dealloc while popover is visible
    if (!_toolItemPopover)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewProjectPopover" bundle:[NSBundle mainBundle]];
        ACNewProjectPopoverController *popoverViewController = (ACNewProjectPopoverController *)[storyboard instantiateInitialViewController];
        popoverViewController.projectsDirectory = self.projectsDirectory;
        _toolItemPopover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
    }
    [_toolItemPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

#pragma mark - Cell Methods and Actions

- (UIImage *)projectIconWithColor:(UIColor *)color
{
    // Icons cache
    STATIC_OBJECT(NSCache, iconCache, [NSCache new]);
    
    // Cell icon
    UIImage *cellIcon = [iconCache objectForKey:color];
    if (!cellIcon)
    {
        cellIcon = [UIImage styleProjectImageWithSize:CGSizeMake(32, 33) labelColor:color];
        [iconCache setObject:cellIcon forKey:color];
    }
    
    return cellIcon;
}

//- (void)labelColorAction:(id)sender
//{
//    if (!popoverLabelColorController)
//    {
//        ACColorSelectionControl *colorControl = [ACColorSelectionControl new];
//        colorControl.colorCellsMargin = 2;
//        colorControl.columns = 3;
//        colorControl.rows = 2;
//        colorControl.colors = [NSArray arrayWithObjects:
//                               [UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1], 
//                               [UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1], 
//                               [UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
//                               [UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
//                               [UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1],
//                               [UIColor styleForegroundColor], nil];
//        [colorControl addTarget:self action:@selector(colorSelectionAction:) forControlEvents:UIControlEventTouchUpInside];
//        
//        UIViewController *viewController = [UIViewController new];
//        viewController.contentSizeForViewInPopover = CGSizeMake(145, 90);
//        viewController.view = colorControl;
//        
//        popoverLabelColorController = [[ECPopoverController alloc] initWithContentViewController:viewController];
//    }
//    
//    // Retrieve cell
//    id cell = sender;
//    while (cell && ![cell isKindOfClass:[UITableViewCell class]])
//        cell = [cell superview];
//    [(ACColorSelectionControl *)popoverLabelColorController.contentViewController.view setUserInfo:cell];
//    
//    [popoverLabelColorController presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
//}

#pragma mark - GridViewDataSource

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [self.directoryPresenter.fileURLs count];
}

- (CGSize)sizeForItemsInGMGridView:(GMGridView *)gridView
{
    return CGSizeMake(320.0, 150.0);
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    // Backgrounds images
    STATIC_OBJECT(UIImage, cellBackgroundImage, [UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    STATIC_OBJECT(UIImage, cellHighlightedImage, [UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    
    // Create cell
    ACProjectCell *cell = (ACProjectCell *)[self.gridView dequeueReusableCell];
    if (cell == nil)
    {
        cell = [[ACProjectCell alloc] init];
        [[NSBundle mainBundle] loadNibNamed:@"ProjectCell" owner:cell options:nil];
        
        // Setup project icon
        [cell.normalView.imageView setImage:[self projectIconWithColor:[UIColor styleForegroundColor]]];
        [cell.editingView.imageView setImage:[self projectIconWithColor:[UIColor styleForegroundColor]]];
    }
    
    
    // Setup project title
    [cell.normalView.textLabel setText:[[[self.directoryPresenter.fileURLs objectAtIndex:index] lastPathComponent] stringByDeletingPathExtension]];
    [cell.editingView.textField setText:[[[self.directoryPresenter.fileURLs objectAtIndex:index] lastPathComponent] stringByDeletingPathExtension]];
    [cell.editingView.textField setTag:index];
    [cell.editingView.textField setDelegate:self];
    
    [cell.normalView.openButton setTag:index];
    [cell.normalView.openButton addTarget:self action:@selector(_openButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.editingView.deleteButton setTag:index];
    [cell.editingView.deleteButton addTarget:self action:@selector(_deleteButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if (self.editing)
        cell.contentView = cell.editingView;
    else
        cell.contentView = cell.normalView;
    
    return cell;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.text = [[[self.directoryPresenter.fileURLs objectAtIndex:textField.tag] lastPathComponent] stringByDeletingPathExtension];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![textField.text length])
        return NO;
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:textField.tag];
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForMoving error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager moveItemAtURL:newURL toURL:[[[newURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:textField.text] URLByAppendingPathExtension:@"weakpkg"] error:NULL];
    }];
    [textField resignFirstResponder];
    [self.gridView reloadData];
    return YES;
}

- (void)_openButtonAction:(id)sender
{
    ECASSERT(!self.editing);
    NSInteger rowIndex = [(UIControl *)sender tag];
    ECASSERT(rowIndex >= 0);
    [self.tab pushURL:[self.directoryPresenter.fileURLs objectAtIndex:rowIndex]];
}

- (void)_deleteButtonAction:(id)sender
{
    ECASSERT(self.editing);
    NSInteger rowIndex = [(UIControl *)sender tag];
    ECASSERT(rowIndex >= 0);
    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:rowIndex];
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager removeItemAtURL:newURL error:NULL];
    }];
}

@end
