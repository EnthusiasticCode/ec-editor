//
//  ProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ReactiveCocoa/NSObject+RACKVOWrapper.h>

#import "ProjectBrowserController.h"
#import "AppStyle.h"
#import "ColorSelectionControl.h"

#import "ArtCodeAppDelegate.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"

#import "DocSetDownloadManager.h"
#import "DocSet.h"

#import "SingleTabController.h"

#import "NSURL+Utilities.h"
#import "NSFileCoordinator+CoordinatedFileManagement.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "ArchiveUtilities.h"
#import "BezelAlert.h"


@interface ProjectBrowserController ()

@property (nonatomic, strong, readonly) NSArray *gridElements;
@property (nonatomic, strong) GridView *gridView;
@property (nonatomic, strong) UIView *hintView;

- (void)_toolNormalAddAction:(id)sender;
- (void)_toolEditDeleteAction:(id)sender;
- (void)_toolEditDuplicateAction:(id)sender;
- (void)_toolEditExportAction:(id)sender;

@end

#pragma mark -

@implementation ProjectBrowserController {
  UIPopoverController *_toolItemPopover;
  
  NSArray *_toolItemsNormal;
  NSArray *_toolItemsEditing;
  
  UIActionSheet *_toolItemDeleteActionSheet;
  UIActionSheet *_toolItemDuplicateActionSheet;
  UIActionSheet *_toolItemExportActionSheet;
  
  UIImage *_cellNormalBackground;
  UIImage *_cellSelectedBackground;
}

@synthesize gridElements=_gridElements, gridView = _gridView, hintView = _hintView;
@synthesize projectsSet = _projectsSet;

- (NSArray *)gridElements {
  if (!_gridElements) {
    NSMutableArray *elements = [NSMutableArray arrayWithArray:[[ArtCodeProjectSet defaultSet] projects].array];
    [elements addObjectsFromArray:[[DocSetDownloadManager sharedDownloadManager] downloadedDocSets]];
    _gridElements = [elements sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      return [[obj1 name] compare:[obj2 name] options:NSCaseInsensitiveSearch];
    }];
    
    // Side effect to update hint view
    if (_gridElements.count > 0) {
      [_hintView removeFromSuperview];
    } else {
      [self.view addSubview:self.hintView];
    }
  }
  return _gridElements;
}

- (UIView *)hintView {
  if (!_hintView) {
    _hintView = [[[NSBundle mainBundle] loadNibNamed:@"ProjectsHintsView" owner:nil options:nil] objectAtIndex:0];
    _hintView.frame = self.view.bounds;
  }
  return _hintView;
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
  return NO;
}

#pragma mark - UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (!self)
    return nil;
  
  // RAC
  __weak ProjectBrowserController *this = self;
  [self rac_bind:RAC_KEYPATH_SELF(projectsSet) to:RACAble([ArtCodeProjectSet defaultSet], projects)];
  
  // Update gird view
  [[ArtCodeProjectSet defaultSet].objectsAdded subscribeNext:^(ArtCodeProject *proj) {
    ProjectBrowserController *strongSelf = this;
    if (!strongSelf)
      return;
    NSString *projectName = [proj name];
    __block NSUInteger index = strongSelf->_gridElements.count;
    [strongSelf->_gridElements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if ([projectName compare:[obj name] options:NSCaseInsensitiveSearch] == NSOrderedAscending) {
        index = idx;
        *stop = YES;
      }
    }];
    strongSelf->_gridElements = nil;
    [strongSelf.gridView insertCellsAtIndexes:[NSIndexSet indexSetWithIndex:index] animated:YES];
  }];
  
  [[ArtCodeProjectSet defaultSet].objectsRemoved subscribeNext:^(ArtCodeProject *proj) {
    ProjectBrowserController *strongSelf = this;
    if (!strongSelf)
      return;
    NSString *projectName = [proj name];
    __block NSUInteger index = 0;
    [strongSelf->_gridElements enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      if ([obj isKindOfClass:[ArtCodeProject class]] && [projectName isEqualToString:[obj name]]) {
        index = idx;
        *stop = YES;
      }
    }];
    strongSelf->_gridElements = nil;
    [strongSelf.gridView deleteCellsAtIndexes:[NSIndexSet indexSetWithIndex:index] animated:YES];
  }];
  
  // Update the grid view when a docset gets removed
  // TODO!!! this will never be disposed
  // TODO add case when docset is added
  [[[NSNotificationCenter defaultCenter] rac_addObserverForName:DocSetWillBeDeletedNotification object:nil] subscribeNext:^(NSNotification *note) {
    ProjectBrowserController *strongSelf = this;
    if (!strongSelf)
      return;
    NSUInteger idx = [strongSelf->_gridElements indexOfObjectIdenticalTo:note.object];
    if (idx != NSNotFound) {
      strongSelf->_gridElements = nil;
      [strongSelf.gridView deleteCellsAtIndexes:[NSIndexSet indexSetWithIndex:idx] animated:YES];
    }
  }];
  
  return self;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
  if (editing == self.isEditing)
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

- (NSString *)title
{
  return @"ArtCode";
}

- (void)loadView
{
  [super loadView];
  
  [self.view addSubview:self.gridView];
  self.gridView.frame = self.view.bounds;
  self.gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  self.editButtonItem.title = @"";
  self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
  self.editButtonItem.accessibilityLabel = L(@"Edit");
  
  // Preparing tool items array changed in set editing
  UIBarButtonItem *exportButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Export"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditExportAction:)];
  exportButtonItem.accessibilityLabel = L(@"Export");
  UIBarButtonItem *duplicateButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Duplicate"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDuplicateAction:)];
  duplicateButtonItem.accessibilityLabel = L(@"Duplicate");
  UIBarButtonItem *deleteButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"itemIcon_Delete"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolEditDeleteAction:)];
  deleteButtonItem.accessibilityLabel = L(@"Delete");
  _toolItemsEditing = [NSArray arrayWithObjects:exportButtonItem, duplicateButtonItem, deleteButtonItem, nil];
  
  UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)];
  addButtonItem.accessibilityLabel = L(@"Add");
  _toolItemsNormal = [NSArray arrayWithObject:addButtonItem];
  self.toolbarItems = _toolItemsNormal;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
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
  
  _gridElements = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.gridView reloadData];
}

#pragma mark - Grid View Data Source

- (NSInteger)numberOfCellsForGridView:(GridView *)gridView
{
  return self.gridElements.count;
}

- (GridViewCell *)gridView:(GridView *)gridView cellAtIndex:(NSInteger)cellIndex
{    
  // Create cell
  static NSString *cellIdentifier = @"cell";
  ProjectCell *cell = [gridView dequeueReusableCellWithIdentifier:cellIdentifier];
  if (cell == nil)
  {
    cell = [ProjectCell gridViewCellWithReuseIdentifier:cellIdentifier fromNibNamed:@"ProjectCell" bundle:nil];
    cell.contentInsets = UIEdgeInsetsMake(10, 10, 10, 10);
    
    if (!_cellNormalBackground)
      _cellNormalBackground = [[UIImage imageNamed:@"projectsTableCell_BackgroundNormal"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
    [(UIImageView *)cell.backgroundView setImage:_cellNormalBackground];
    if (!_cellSelectedBackground)
      _cellSelectedBackground = [[UIImage imageNamed:@"projectsTableCell_BackgroundSelected"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
    [(UIImageView *)cell.selectedBackgroundView setImage:_cellSelectedBackground];
  }
  
  // Setup cell
  id element = [self.gridElements objectAtIndex:cellIndex];
  if ([element isKindOfClass:[ArtCodeProject class]]) {
    ArtCodeProject *project = (ArtCodeProject *)element;
    cell.title.text = cell.accessibilityLabel = project.name;
    cell.label.text = @"";
    cell.icon.image = [UIImage styleProjectImageWithSize:cell.icon.bounds.size labelColor:project.labelColor];
    cell.newlyCreatedBadge.hidden = !project.newlyCreatedValue;
    cell.accessibilityHint = L(@"Open the project");
  } else if ([element isKindOfClass:[DocSet class]]) {
    DocSet *docSet = (DocSet *)element;
    cell.title.text = cell.accessibilityLabel = docSet.name;
    cell.label.text = @"";
    cell.icon.image = [UIImage imageNamed:@"projectsIcon_docSet"];
    cell.accessibilityHint = L(@"Open the documentation");
    cell.newlyCreatedBadge.hidden = YES;
  }
  
  // Accessibility
  cell.isAccessibilityElement = YES;
  cell.accessibilityTraits = UIAccessibilityTraitButton;
  
  return cell;
}

#pragma mark - Grid View Delegate

- (void)gridView:(GridView *)gridView willSelectCellAtIndex:(NSInteger)cellIndex {
  if (!self.isEditing) {
    id element = [self.gridElements objectAtIndex:cellIndex];
    if ([element isKindOfClass:[ArtCodeProject class]]) {
      [(ArtCodeProject *)element setNewlyCreatedValue:NO];
      [self.artCodeTab pushProject:element];
    } else if ([element isKindOfClass:[DocSet class]]) {
      [self.artCodeTab pushDocSetURL:[(DocSet *)element docSetURLForNode:nil]];
    }
  }
}

- (void)gridView:(GridView *)gridView didSelectCellAtIndex:(NSInteger)cellIndex
{
  if (self.isEditing) {
    BOOL enable = [gridView indexForSelectedCell] != -1;
    [_toolItemsEditing enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
      [(UIButton *)item.customView setEnabled:enable];
    }];
  }
}

- (void)gridView:(GridView *)gridView didDeselectCellAtIndex:(NSInteger)cellIndex
{
  // Will update editing items like in select
  [self gridView:gridView didSelectCellAtIndex:cellIndex];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
  ASSERT(self.isEditing);
  ASSERT([self.gridView indexForSelectedCell] != -1);
  
  if (actionSheet == _toolItemDeleteActionSheet) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
      NSIndexSet *cellsToRemove = [self.gridView indexesForSelectedCells];
      [self setEditing:NO animated:YES];
      
      // Remove projects
      NSArray *oldElements = self.gridElements;
      [oldElements enumerateObjectsAtIndexes:cellsToRemove options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ArtCodeProject class]]) {
          [[ArtCodeProjectSet defaultSet] removeProject:obj completionHandler:^(NSError *error) {
            // Show bezel alert
            [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"Item removed") plural:L(@"%u items removed") count:[cellsToRemove count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
          }];
        } else if ([obj isKindOfClass:[DocSet class]]) {
          [[DocSetDownloadManager sharedDownloadManager] deleteDocSet:obj];
          // Show bezel alert
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"Item removed") plural:L(@"%u items removed") count:[cellsToRemove count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
        }
      }];
      
    }
  } else if (actionSheet == _toolItemDuplicateActionSheet) {
    self.loading = YES;
    NSIndexSet *cellsToDuplicate = [self.gridView indexesForSelectedCells];
    NSInteger cellsToDuplicateCount = [cellsToDuplicate count];
    __block NSInteger progress = 0;
    [self setEditing:NO animated:YES];
    
    [cellsToDuplicate enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      [(ArtCodeProject *)[[[ArtCodeProjectSet defaultSet] projects] objectAtIndex:idx] duplicateWithCompletionHandler:^(ArtCodeProject *duplicate) {
        if (++progress == cellsToDuplicateCount) {
          self.loading = NO;
        }
      }];
    }];
  } else if (actionSheet == _toolItemExportActionSheet) {
    if (buttonIndex == 0) // export to iTunes
    {
      NSIndexSet *cellsToExport = [self.gridView indexesForSelectedCells];
      [self setEditing:NO animated:YES];
      
      self.loading = YES;
      NSInteger cellsToExportCount = [cellsToExport count];
      __block NSInteger progress = 0;
      void (^progressBlock)() = ^{
        // Block to advance the progress count and terminate loading phase when done
        if (++progress == cellsToExportCount) {
          self.loading = NO;
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"Project exported") plural:L(@"%u projects exported") count:cellsToExportCount] imageNamed:BezelAlertOkIcon displayImmediatly:YES];
        }
      };
      [self.gridElements enumerateObjectsAtIndexes:cellsToExport options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ArtCodeProject class]]) {
          ArtCodeProject *project = obj;
          NSURL *zipURL = [[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:[project.name stringByAppendingPathExtension:@"zip"]];
          [ArchiveUtilities coordinatedCompressionOfFilesAtURLs:@[ project.fileURL ] toArchiveAtURL:zipURL renameIfNeeded:YES completionHandler:^(NSError *error, NSURL *newURL) {
            // TODO error handling?
            progressBlock();
          }];
        } else {
          // Not a project
          progressBlock();
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Only projects can be exported") imageNamed:BezelAlertForbiddenIcon displayImmediatly:NO];
        }
      }];
    }
    else if (buttonIndex == 1) // send mail
    {
      MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
      mailComposer.mailComposeDelegate = self;
      mailComposer.navigationBar.barStyle = UIBarStyleDefault;
      mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
      
      // Compressing projects to export
      self.loading = YES;
      NSIndexSet *cellsToExport = [self.gridView indexesForSelectedCells];
      [self setEditing:NO animated:YES];
      
      NSMutableString *subject = [NSMutableString new];
      NSInteger cellsToExportCount = [cellsToExport count];
      __block NSInteger progress = 0;
      NSURL *temporaryDirectory = [NSURL temporaryDirectory];
      [[NSFileManager defaultManager] createDirectoryAtURL:temporaryDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
      void (^progressCompletion)() = ^ {
        // Complete process
        if (++progress == cellsToExportCount) {
          // Add mail subject
          if ([subject length] > 2) {
            [subject replaceCharactersInRange:NSMakeRange([subject length] - 2, 2) withString:(cellsToExportCount == 1 ? @" project" : @" projects")];
            [mailComposer setSubject:subject];
          } else {
            [mailComposer setSubject:L(@"ArtCode exported project")];
          }
          
          // Add body
          if (cellsToExportCount == 1)
            [mailComposer setMessageBody:@"<br/><p>Open this file with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained project.</p>" isHTML:YES];
          else
            [mailComposer setMessageBody:@"<br/><p>Open this files with <a href=\"http://www.artcodeapp.com/\">ArtCode</a> to view the contained projects.</p>" isHTML:YES];
          
          // Present
          [self presentViewController:mailComposer animated:YES completion:nil];
          [mailComposer.navigationBar.topItem.leftBarButtonItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
          self.loading = NO;
        }
      };
      // Enumerate elements to export
      [self.gridElements enumerateObjectsAtIndexes:cellsToExport options:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[ArtCodeProject class]]) {
          ArtCodeProject *project = obj;
          
          // Generate mail subject
          [subject appendFormat:@"%@, ", project.name];
          
          // Process project
          NSURL *zipURL = [temporaryDirectory URLByAppendingPathComponent:[project.name stringByAppendingPathExtension:@"zip"]];
          [ArchiveUtilities coordinatedCompressionOfFilesAtURLs:[NSArray arrayWithObject:project.fileURL] toArchiveAtURL:zipURL renameIfNeeded:NO completionHandler:^(NSError *error, NSURL *newURL) {
            // Add attachment
            [mailComposer addAttachmentData:[NSData dataWithContentsOfURL:zipURL] mimeType:@"application/zip" fileName:[zipURL lastPathComponent]];
            [[NSFileManager defaultManager] removeItemAtURL:zipURL error:NULL];
            progressCompletion();
          }];
        } else {
          // Ignore non projects
          progressCompletion();
        }
      }];
    }
  }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  if (result == MFMailComposeResultSent)
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  [self dismissModalViewControllerAnimated:YES];
}

#pragma mark - Private Methods

- (GridView *)gridView
{
  if (!_gridView && self.isViewLoaded)
  {
    _gridView = [[GridView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    _gridView.allowMultipleSelectionDuringEditing = YES;
    _gridView.dataSource = self;
    _gridView.delegate = self;
    _gridView.rowHeight = 120 + 15;
    _gridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _gridView.alwaysBounceVertical = YES;
    _gridView.cellInsets = UIEdgeInsetsMake(15, 15, 15, 15);
    _gridView.backgroundView = [UIView new];
    _gridView.backgroundView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"projectsTable_Background"]];
    _gridView.accessibilityIdentifier = @"projects grid";
  }
  return _gridView;
}

- (void)_toolNormalAddAction:(id)sender
{
  
  // Removing the lazy loading could cause the old popover to be overwritten by the new one causing a dealloc while popover is visible
  if (!_toolItemPopover)
  {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewProjectPopover" bundle:nil];
    UINavigationController *newProjectNavigationController = (UINavigationController *)[storyboard instantiateInitialViewController];
    [newProjectNavigationController.navigationBar setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    newProjectNavigationController.artCodeTab = self.artCodeTab;
    _toolItemPopover = [[UIPopoverController alloc] initWithContentViewController:newProjectNavigationController];
    _toolItemPopover.popoverBackgroundViewClass = [ShapePopoverBackgroundView class];
    newProjectNavigationController.presentingPopoverController = _toolItemPopover;
  }
  [(UINavigationController *)_toolItemPopover.contentViewController popToRootViewControllerAnimated:NO];
  [_toolItemPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (void)_toolEditDeleteAction:(id)sender
{
  if (!_toolItemDeleteActionSheet)
  {
    _toolItemDeleteActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:L(@"Delete permanently") otherButtonTitles:nil];
    _toolItemDeleteActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolItemDeleteActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditExportAction:(id)sender
{
  if (!_toolItemExportActionSheet)
  {
    _toolItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Export to iTunes"), ([MFMailComposeViewController canSendMail] ? L(@"Send via E-Mail") : nil), nil];
    _toolItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender {
  ASSERT(self.isEditing);
  ASSERT([self.gridView indexForSelectedCell] != -1);
  
  if (!_toolItemDuplicateActionSheet) {
    _toolItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Duplicate"), nil];
    _toolItemDuplicateActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolItemDuplicateActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

@end

#pragma mark -

@implementation ProjectCell

@synthesize title;
@synthesize label;
@synthesize icon;
@synthesize newlyCreatedBadge;

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

