//
//  ACProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "ACProjectTableController.h"
#import "AppStyle.h"
#import "ACColorSelectionControl.h"

#import "ArtCodeAppDelegate.h"
#import "ACApplication.h"
#import "ACTab.h"

#import "ACNewProjectPopoverController.h"

#import <ECFoundation/ECDirectoryPresenter.h>

#import <ECUIKit/ECBezelAlert.h>

static void * directoryPresenterFileURLsObservingContext;

#define STATIC_OBJECT(typ, nam, init) static typ *nam = nil; if (!nam) nam = init

@interface ACProjectTableController () {
    UIPopoverController *_toolItemPopover;
    
    NSArray *_toolItemsNormal;
    NSArray *_toolItemsEditing;

    UIActionSheet *_toolItemDeleteActionSheet;
    UIActionSheet *_toolItemExportActionSheet;
    
    UIImage *_cellNormalBackground;
    UIImage *_cellSelectedBackground;
    
    NSInteger additionals;
}
@property (nonatomic, strong) ECGridView *gridView;

/// Represent a directory's contents.
@property (nonatomic, strong) ECDirectoryPresenter *directoryPresenter;
- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDeleteAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

@end

#pragma mark - Implementation
#pragma mark -

@implementation ACProjectTableController

#pragma mark - Properties

@synthesize tab = _tab;
@synthesize gridView = _gridView;
@synthesize projectsDirectory = _projectsDirectory, directoryPresenter = _directoryPresenter;

- (ECGridView *)gridView
{
    if (!_gridView)
    {
        _gridView = [[ECGridView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        _gridView.allowMultipleSelectionDuringEditing = YES;
        _gridView.dataSource = self;
        _gridView.delegate = self;
        _gridView.rowHeight = 120 + 15;
        _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _gridView.alwaysBounceVertical = YES;
        _gridView.cellInsets = UIEdgeInsetsMake(15, 15, 15, 15);
        _gridView.backgroundView = [UIView new];
        _gridView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"projectsTable_Background"]];
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
    if (editing == self.editing)
        return;
    
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    self.editButtonItem.title = @"";
    
    if (!editing)
    {
        self.toolbarItems = _toolItemsNormal;
    }
    else
    {
        self.toolbarItems = _toolItemsEditing;
        [_toolItemsEditing enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
            [(UIButton *)item.customView setEnabled:NO];
        }];
    }
    
    [self.gridView setEditing:editing animated:animated];
    
    [self didChangeValueForKey:@"editing"];
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
    self.view = self.gridView;
    
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Preparing tool items array changed in set editing
    _toolItemsEditing = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)], [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)], nil];
    
    _toolItemsNormal = [NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)]];
    self.toolbarItems = _toolItemsNormal;
    
    [self setEditing:NO animated:NO];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    _toolItemPopover = nil;
    
    _toolItemsNormal = nil;
    _toolItemsEditing = nil;
    
    _toolItemDeleteActionSheet = nil;
    _toolItemExportActionSheet = nil;
    
    _cellNormalBackground = nil;
    _cellSelectedBackground = nil;
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

#pragma mark - Grid View Data Source

- (NSInteger)numberOfCellsForGridView:(ECGridView *)gridView
{
//    return additionals;
    return [self.directoryPresenter.fileURLs count];
}

- (ECGridViewCell *)gridView:(ECGridView *)gridView cellAtIndex:(NSInteger)cellIndex
{
    // Backgrounds images
    STATIC_OBJECT(UIImage, cellBackgroundImage, [UIImage styleBackgroundImageWithColor:[UIColor styleBackgroundColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    STATIC_OBJECT(UIImage, cellHighlightedImage, [UIImage styleBackgroundImageWithColor:[UIColor styleHighlightColor] borderColor:[UIColor styleForegroundColor] insets:UIEdgeInsetsMake(4, 7, 4, 7) arrowSize:CGSizeZero roundingCorners:UIRectCornerAllCorners]);
    
    // Create cell
    static NSString *cellIdentifier = @"cell";
    ACProjectCell *cell = [gridView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil)
    {
        cell = [ACProjectCell gridViewCellWithReuseIdentifier:cellIdentifier fromNibNamed:@"ProjectCell" bundle:nil];
        cell.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        if (!_cellNormalBackground)
            _cellNormalBackground = [[UIImage imageNamed:@"projectsTableCell_BackgroundNormal"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
        [(UIImageView *)cell.backgroundView setImage:_cellNormalBackground];
        if (!_cellSelectedBackground)
            _cellSelectedBackground = [[UIImage imageNamed:@"projectsTableCell_BackgroundSelected"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
        [(UIImageView *)cell.selectedBackgroundView setImage:_cellSelectedBackground];
    }
    
    // Setup project title
    cell.title.text = [[[self.directoryPresenter.fileURLs objectAtIndex:cellIndex] lastPathComponent] stringByDeletingPathExtension];
    cell.label.text = @"";
    cell.icon.image = [UIImage styleProjectImageWithSize:cell.icon.bounds.size labelColor:[UIColor styleThemeColorOne]];

//    cell.title.text = [NSString stringWithFormat:@"%d", cellIndex];
    
    return cell;
}

#pragma mark - Grid View Delegate

- (void)gridView:(ECGridView *)gridView willSelectCellAtIndex:(NSInteger)cellIndex
{
    if (!self.isEditing)
    {
        [self.tab pushURL:[self.directoryPresenter.fileURLs objectAtIndex:cellIndex]];
    }
}

- (void)gridView:(ECGridView *)gridView didSelectCellAtIndex:(NSInteger)cellIndex
{
    if (self.isEditing)
    {
        BOOL enable = [gridView indexForSelectedCell] != -1;
        [_toolItemsEditing enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
            [(UIButton *)item.customView setEnabled:enable];
        }];
    }
//    additionals--;
//    [gridView deleteCellsAtIndexes:[NSIndexSet indexSetWithIndex:cellIndex] animated:YES];
}

- (void)gridView:(ECGridView *)gridView didDeselectCellAtIndex:(NSInteger)cellIndex
{
    // Will update editing items like in select
    [self gridView:gridView didSelectCellAtIndex:cellIndex];
}

//- (void)textFieldDidEndEditing:(UITextField *)textField
//{
//    textField.text = [[[self.directoryPresenter.fileURLs objectAtIndex:textField.tag] lastPathComponent] stringByDeletingPathExtension];
//}
//
//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    if (![textField.text length])
//        return NO;
//    NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:textField.tag];
//    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
//    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForMoving error:NULL byAccessor:^(NSURL *newURL) {
//        NSFileManager *fileManager = [[NSFileManager alloc] init];
//        [fileManager moveItemAtURL:newURL toURL:[[[newURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:textField.text] URLByAppendingPathExtension:@"weakpkg"] error:NULL];
//    }];
//    [textField resignFirstResponder];
//    [self.gridView reloadData];
//    return YES;
//}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    ECASSERT(self.isEditing);
    ECASSERT([self.gridView indexForSelectedCell] != -1);
    
    if (actionSheet == _toolItemDeleteActionSheet)
    {
        ECASSERT(buttonIndex == actionSheet.destructiveButtonIndex);
        
        // Remove files
        NSIndexSet *cellsToRemove = [self.gridView indexesForSelectedCells];
        [cellsToRemove enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            
            NSURL *fileURL = [self.directoryPresenter.fileURLs objectAtIndex:idx];
            ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
            [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                [fileManager removeItemAtURL:newURL error:NULL];
            }];
        }];
        
        // Remove cells from grid
        [self.gridView deleteCellsAtIndexes:cellsToRemove animated:YES];
        
        // Show bezel alert
        [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:([cellsToRemove count] == 1 ? @"Project removed" : [NSString stringWithFormat:@"%u projects removed", [cellsToRemove count]]) image:nil displayImmediatly:YES];
    }
    else if (actionSheet == _toolItemExportActionSheet)
    {
        if (buttonIndex == 0) // export to iTunes
        {
            
        }
        else if (buttonIndex == 1) // send mail
        {
            // TODO create content and zips
            
            [self setEditing:NO animated:YES];
            
            MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
            mailComposer.mailComposeDelegate = self;
            mailComposer.navigationBar.barStyle = UIBarStyleBlack;
            mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
            
#warning TODO replace
            NSString *content = @"";
            NSString *pageLink = @"http://mugunthkumar.com/mygreatapp";
            NSString *iTunesLink = @"http://link-to-mygreatapp";
            NSString *emailBody =
            [NSString stringWithFormat:@"%@<br/><br/><p>Sent from <a href = '%@'>MyGreatApp</a> on iPad. <a href = '%@'>Download</a> yours from AppStore now.</p>", content, pageLink, iTunesLink];
            
            [mailComposer setSubject:@"TODO"];
            [mailComposer setMessageBody:emailBody isHTML:YES];
            
            [self presentModalViewController:mailComposer animated:YES];
        }
    }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent)
        [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" image:nil displayImmediatly:YES];
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (void)_toolNormalAddAction:(id)sender
{
//    additionals++;
//    [self.gridView insertCellsAtIndexes:[NSIndexSet indexSetWithIndex:(additionals - 1)] animated:YES];
    
    // Removing the lazy loading could cause the old popover to be overwritten by the new one causing a dealloc while popover is visible
    if (!_toolItemPopover)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewProjectPopover" bundle:nil];
        ACNewProjectPopoverController *popoverViewController = (ACNewProjectPopoverController *)[storyboard instantiateInitialViewController];
        popoverViewController.projectsDirectory = self.projectsDirectory;
        _toolItemPopover = [[UIPopoverController alloc] initWithContentViewController:popoverViewController];
    }
    [_toolItemPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditDeleteAction:(id)sender
{
    if (!_toolItemDeleteActionSheet)
    {
        _toolItemDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Delete permanently" otherButtonTitles:nil];
        _toolItemDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolItemDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditExportAction:(id)sender
{
    if (!_toolItemExportActionSheet)
    {
        _toolItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Export to iTunes", ([MFMailComposeViewController canSendMail] ? @"Send via E-Mail" : nil), nil];
        _toolItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    }
    [_toolItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender
{
    ECASSERT(self.isEditing);
    ECASSERT([self.gridView indexForSelectedCell] != -1);
    
    NSIndexSet *cellsToDuplicate = [self.gridView indexesForSelectedCells];
    
    // TODO
}

@end


@implementation ACProjectCell

@synthesize title;
@synthesize label;
@synthesize icon;

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    static NSString *jitterAnimationKey = @"jitter";
    
    if (editing)
    {
        CGFloat angle = RADIANS(0.7);
        CABasicAnimation *jitter = [CABasicAnimation animationWithKeyPath:@"transform"];
        jitter.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-angle, 0, 0, 1)];
        jitter.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(angle, 0, 0, 1)];
        jitter.autoreverses = YES;
        jitter.duration = 0.125;
        jitter.timeOffset = (CGFloat)rand() / RAND_MAX;
        jitter.repeatCount = CGFLOAT_MAX;
        
        [self.layer addAnimation:jitter forKey:jitterAnimationKey];
    }
    else
    {
        [self.layer removeAnimationForKey:jitterAnimationKey];
    }
}

@end

