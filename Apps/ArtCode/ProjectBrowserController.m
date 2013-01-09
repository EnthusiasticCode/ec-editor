//
//  ProjectsTableController.m
//  ACUI
//
//  Created by Nicola Peduzzi on 17/06/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "NSNotificationCenter+RACSupport.h"

#import "ProjectBrowserController.h"
#import "NewProjectController.h"
#import "AppStyle.h"
#import "ColorSelectionControl.h"

#import "ArtCodeAppDelegate.h"

#import "ArtCodeTab.h"
#import "ArtCodeLocation.h"
#import "ArtCodeProject.h"
#import "ArtCodeProjectSet.h"

#import "SingleTabController.h"

#import "NSURL+Utilities.h"
#import "FileSystemItem.h"
#import "UIViewController+Utilities.h"
#import "NSString+PluralFormat.h"
#import "ArchiveUtilities.h"
#import "BezelAlert.h"

#import "UIBarButtonItem+BlockAction.h"

static NSString * const ProjectCellIdentifier = @"ProjectCell";

@interface ProjectBrowserController () <UIActionSheetDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) NSArray *gridElements;

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

@synthesize gridElements=_gridElements;
@synthesize projectsSet = _projectsSet;

- (NSArray *)gridElements {
  if (!_gridElements) {
    NSArray *elements = [[ArtCodeProjectSet defaultSet] projects].array;
    _gridElements = [elements sortedArrayUsingComparator:^NSComparisonResult(ArtCodeProject *obj1, ArtCodeProject *obj2) {
      return [[obj1 name] compare:[obj2 name] options:NSCaseInsensitiveSearch];
    }];
    
    // Side effect to update hint view
    if (_gridElements.count > 0) {
      [self.hintView removeFromSuperview];
    } else {
      [self.view addSubview:self.hintView];
			self.hintView.frame = self.view.bounds;
    }
  }
  return _gridElements;
}

+ (BOOL)automaticallyNotifiesObserversOfEditing
{
  return NO;
}

#pragma mark - UIViewController

- (id)init {
  self = [super initWithNibName:@"ProjectsBrowserController" bundle:nil];
  if (!self)
    return nil;
  
  // RAC
  @weakify(self);
  [self rac_bind:@keypath(self.projectsSet) to:RACAble([ArtCodeProjectSet defaultSet], projects)];
  
  // Update gird view
  [[ArtCodeProjectSet defaultSet].objectsAdded subscribeNext:^(ArtCodeProject *proj) {
    @strongify(self);
    NSString *projectName = [proj name];
    __block NSUInteger index = self.gridElements.count;
    [self.gridElements enumerateObjectsUsingBlock:^(ArtCodeProject *obj, NSUInteger idx, BOOL *stop) {
      if ([projectName compare:[obj name] options:NSCaseInsensitiveSearch] == NSOrderedAscending) {
        index = idx;
        *stop = YES;
      }
    }];
    self.gridElements = nil;
		
		[self.collectionView insertItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];
  }];
  
  [[ArtCodeProjectSet defaultSet].objectsRemoved subscribeNext:^(ArtCodeProject *proj) {
    @strongify(self);
    NSString *projectName = [proj name];
    __block NSUInteger index = 0;
    [self.gridElements enumerateObjectsUsingBlock:^(ArtCodeProject *obj, NSUInteger idx, BOOL *stop) {
      if ([obj isKindOfClass:[ArtCodeProject class]] && [projectName isEqualToString:[obj name]]) {
        index = idx;
        *stop = YES;
      }
    }];
    self.gridElements = nil;
		[self.collectionView deleteItemsAtIndexPaths:@[ [NSIndexPath indexPathForItem:index inSection:0] ]];
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
	
	for (NSIndexPath *itemPath in self.collectionView.indexPathsForSelectedItems) {
    [self.collectionView deselectItemAtIndexPath:itemPath animated:animated];
	}
	for (ProjectCell *cell in self.collectionView.visibleCells) {
    cell.jiggle = editing;
	}
  
  [self didChangeValueForKey:@"editing"];
}

- (NSString *)title
{
  return @"ArtCode";
}

- (void)loadView {
  [super loadView];
	  
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
  _toolItemsEditing = @[exportButtonItem, duplicateButtonItem, deleteButtonItem];
  
  UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabBar_TabAddButton"] style:UIBarButtonItemStylePlain target:self action:@selector(_toolNormalAddAction:)];
  addButtonItem.accessibilityLabel = L(@"Add");
  _toolItemsNormal = @[addButtonItem];
  self.toolbarItems = _toolItemsNormal;
}

- (void)viewDidLoad {
  [super viewDidLoad];
	
	[self.collectionView registerNib:[UINib nibWithNibName:ProjectCellIdentifier bundle:nil] forCellWithReuseIdentifier:ProjectCellIdentifier];
	self.collectionView.allowsMultipleSelection = YES;
	self.collectionView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"projectsTable_Background"]];
	self.collectionView.accessibilityIdentifier = @"projects collection";
	
	ProjectCollectionLayout *layout = (ProjectCollectionLayout *)self.collectionView.collectionViewLayout;
	layout.sectionInset = UIEdgeInsetsMake(15, 15, 15, 15);
	layout.itemHeight = 100;
	layout.interItemSpacing = 15;
	layout.numberOfColumns = 2;
	
  [self setEditing:NO animated:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
	
  // Fix to show hint view on empty app start
  if (self.gridElements.count > 0) {
    [self.hintView removeFromSuperview];
  } else {
    [self.view addSubview:self.hintView];
		self.hintView.frame = self.view.bounds;
  }
}

#pragma mark - Collection View Data Source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return self.gridElements.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	ProjectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ProjectCellIdentifier forIndexPath:indexPath];
	
	ArtCodeProject *project = self.gridElements[indexPath.item];
	cell.title.text = cell.accessibilityLabel = project.name;
	cell.label.text = @"";
	cell.icon.image = [UIImage styleProjectImageWithSize:cell.icon.bounds.size labelColor:project.labelColor];
	cell.newlyCreatedBadge.hidden = !project.newlyCreatedValue;

	cell.accessibilityHint = L(@"Open the project");
	cell.isAccessibilityElement = YES;
  cell.accessibilityTraits = UIAccessibilityTraitButton;
	
	cell.jiggle = self.isEditing;
	
	return cell;
}

#pragma mark - Collection View Delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (self.isEditing) {
    BOOL enable = collectionView.indexPathsForSelectedItems.count > 0;
    [_toolItemsEditing enumerateObjectsUsingBlock:^(UIBarButtonItem *item, NSUInteger idx, BOOL *stop) {
      [(UIButton *)item.customView setEnabled:enable];
    }];
  } else {
    id element = self.gridElements[indexPath.item];
    if ([element isKindOfClass:[ArtCodeProject class]]) {
      [(ArtCodeProject *)element setNewlyCreatedValue:NO];
      [self.artCodeTab pushProject:element];
    }
  }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
	// Will update editing items like in select
	[self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
  ASSERT(self.isEditing);
  ASSERT(self.collectionView.indexPathsForSelectedItems.count > 0);
  
  if (actionSheet == _toolItemDeleteActionSheet) {
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
			NSArray *cellsToRemove = self.collectionView.indexPathsForSelectedItems;
      [self setEditing:NO animated:YES];
      
      // Remove projects
      NSArray *oldElements = self.gridElements;
			for (NSIndexPath *itemPath in cellsToRemove) {
				[[ArtCodeProjectSet defaultSet] removeProject:oldElements[itemPath.item] completionHandler:^(NSError *error) {
					// Show bezel alert
					if (error) {
						[[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Can not remove") imageNamed:BezelAlertCancelIcon displayImmediatly:NO];
					} else {
						[[BezelAlert defaultBezelAlert] addAlertMessageWithText:[NSString stringWithFormatForSingular:L(@"Item removed") plural:L(@"%u items removed") count:[cellsToRemove count]] imageNamed:BezelAlertCancelIcon displayImmediatly:YES];
					}
				}];
			}
    }
  } else if (actionSheet == _toolItemDuplicateActionSheet) {
		if (buttonIndex == 0) {
			self.loading = YES;
			NSArray *cellsToDuplicate = self.collectionView.indexPathsForSelectedItems;
			NSInteger cellsToDuplicateCount = [cellsToDuplicate count];
			__block NSInteger progress = 0;
			[self setEditing:NO animated:YES];
			
			for (NSIndexPath *itemPath in cellsToDuplicate) {
				[(ArtCodeProject *)self.gridElements[itemPath.item] duplicateWithCompletionHandler:^(ArtCodeProject *duplicate) {
					if (++progress == cellsToDuplicateCount) {
						self.loading = NO;
					}
				}];
			}
		}
  } else if (actionSheet == _toolItemExportActionSheet) {
		switch (buttonIndex) {
			case 0: // Rename
			{
				if (self.collectionView.indexPathsForSelectedItems.count != 1) {
          [[BezelAlert defaultBezelAlert] addAlertMessageWithText:L(@"Select a single project to rename") imageNamed:BezelAlertForbiddenIcon displayImmediatly:YES];
          break;
        }
				//
				UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"NewProjectPopover" bundle:nil];
				NewProjectController *projectEditor = (NewProjectController *)[storyboard instantiateViewControllerWithIdentifier:@"ProjectEditor"];
				//
				NSIndexPath *indexPathOfProjectToEdit = self.collectionView.indexPathsForSelectedItems[0];
				ArtCodeProject *projectToEdit = self.gridElements[indexPathOfProjectToEdit.item];
				// Prepare the editing view from a NewProjectController
				projectEditor.navigationItem.title = L(@"Edit project");
				[projectEditor.navigationItem.rightBarButtonItem setTitle:L(@"Done")];
				[projectEditor.navigationItem.rightBarButtonItem setActionBlock:^(id sender) {
					if (projectEditor.projectNameTextField.text.length == 0) {
						projectEditor.descriptionLabel.text = L(@"Invalid name for a project");
					}
					projectToEdit.name = projectEditor.projectNameTextField.text;
					if (projectEditor.projectColorSelection.selectedColor != nil) {
						projectToEdit.labelColor = projectEditor.projectColorSelection.selectedColor;
					}
					[self dismissViewControllerAnimated:YES completion:nil];
					[self setEditing:NO animated:YES];
					[self.collectionView reloadItemsAtIndexPaths:@[ indexPathOfProjectToEdit ]];
				}];
				// Cancel button
				UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc] initWithTitle:L(@"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(dismissModalViewControllerAnimated:)];
				[cancelItem setBackgroundImage:[UIImage styleNormalButtonBackgroundImageForControlState:UIControlStateNormal] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
				projectEditor.navigationItem.leftBarButtonItem = cancelItem;
				//
				UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:projectEditor];
				navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:navigationController animated:YES completion:^{
					projectEditor.projectNameTextField.text = projectToEdit.name;
					projectEditor.projectColorSelection.selectedColor = projectToEdit.labelColor;
					projectEditor.descriptionLabel.text = @"";
				}];
			} break;
				
			case 1: // export to iTunes
			{
				NSArray *cellsToExport = self.collectionView.indexPathsForSelectedItems;
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
				for (NSIndexPath *itemPath in cellsToExport) {
						ArtCodeProject *project = self.gridElements[itemPath.item];
						NSURL *zipURL = [[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:[project.name stringByAppendingPathExtension:@"zip"]];
						[ArchiveUtilities compressFileAtURLs:@[project.fileURL] completionHandler:^(NSURL *temporaryDirectoryURL) {
							if (temporaryDirectoryURL) {
								[[NSFileManager defaultManager] moveItemAtURL:[temporaryDirectoryURL URLByAppendingPathComponent:@"Archive.zip"] toURL:zipURL error:NULL];
								[[NSFileManager defaultManager] removeItemAtURL:temporaryDirectoryURL error:NULL];
							}
							progressBlock();
						}];
				}
			} break;
				
			case 2:
			{
				MFMailComposeViewController *mailComposer = [[MFMailComposeViewController alloc] init];
				mailComposer.mailComposeDelegate = self;
				mailComposer.navigationBar.barStyle = UIBarStyleDefault;
				mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
				
				// Compressing projects to export
				self.loading = YES;
				NSArray *cellsToExport = self.collectionView.indexPathsForSelectedItems;
				[self setEditing:NO animated:YES];
				
				NSMutableString *subject = [[NSMutableString alloc] init];
				NSInteger cellsToExportCount = [cellsToExport count];
				__block NSInteger progress = 0;
				// Complete process block
				void (^progressCompletion)() = ^ {
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
				for (NSIndexPath *itemPath in cellsToExport) {
					ArtCodeProject *project = self.gridElements[itemPath.item];
					
					// Generate mail subject
					[subject appendFormat:@"%@, ", project.name];
					
					// Process project
					[ArchiveUtilities compressFileAtURLs:@[project.fileURL] completionHandler:^(NSURL *temporaryDirectoryURL) {
						if (temporaryDirectoryURL) {
							// Add attachment
							NSURL *zipURL = [temporaryDirectoryURL URLByAppendingPathComponent:[project.name stringByAppendingPathExtension:@"zip"]];
							[[NSFileManager defaultManager] moveItemAtURL:[temporaryDirectoryURL URLByAppendingPathComponent:@"Archive.zip"] toURL:zipURL error:NULL];
							[mailComposer addAttachmentData:[NSData dataWithContentsOfURL:zipURL] mimeType:@"application/zip" fileName:[zipURL lastPathComponent]];
							[[NSFileManager defaultManager] removeItemAtURL:temporaryDirectoryURL error:NULL];
							progressCompletion();
						}
					}];
				}
			} break;
				
			default:
				break;
		}
  }
}

#pragma mark - Mail composer Delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  if (result == MFMailComposeResultSent)
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"Mail sent" imageNamed:BezelAlertOkIcon displayImmediatly:YES];
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods

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
    _toolItemPopover.popoverBackgroundViewClass = [ImagePopoverBackgroundView class];
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
    _toolItemExportActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Rename"), L(@"Export to iTunes"), ([MFMailComposeViewController canSendMail] ? L(@"Send via E-Mail") : nil), nil];
    _toolItemExportActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolItemExportActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

- (void)_toolEditDuplicateAction:(id)sender {
  ASSERT(self.isEditing);
  ASSERT(self.collectionView.indexPathsForSelectedItems.count > 0);
  
  if (!_toolItemDuplicateActionSheet) {
    _toolItemDuplicateActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:L(@"Duplicate"), nil];
    _toolItemDuplicateActionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  }
  [_toolItemDuplicateActionSheet showFromRect:[sender frame] inView:[sender superview] animated:YES];
}

@end

#pragma mark -

@implementation ProjectCell

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
  if (!self) return nil;
	
	static UIImage *_cellNormalBackgroundImage = nil;
  if (!_cellNormalBackgroundImage) {
		_cellNormalBackgroundImage = [[UIImage imageNamed:@"projectsTableCell_BackgroundNormal"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
	}
	self.backgroundView = [[UIImageView alloc] initWithImage:_cellNormalBackgroundImage];
	
	static UIImage *_cellSelectedBackgroundImge = nil;
	if (!_cellSelectedBackgroundImge) {
		_cellSelectedBackgroundImge = [[UIImage imageNamed:@"projectsTableCell_BackgroundSelected"] resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];
	}
	self.selectedBackgroundView = [[UIImageView alloc] initWithImage:_cellSelectedBackgroundImge];
	
  return self;
}

#define RADIANS(degrees) ((degrees * M_PI) / 180.0)

- (void)setJiggle:(BOOL)jiggle {
	if (jiggle == _jiggle) return;
	_jiggle = jiggle;
	
  static NSString *jitterAnimationKey = @"jitter";
	
  if (jiggle)
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

#pragma mark

@implementation ProjectCollectionLayout {
	NSDictionary *_layoutAttributes;
	CGSize _collectionViewContentSize;
	NSDictionary *_preAnimationLayoutAttributes;
}

- (void)prepareLayout
{
	// Calculate content size
	NSUInteger rowCount = 0;
	for (NSInteger section = 0; section < self.collectionView.numberOfSections; ++section) {
		rowCount += ([self.collectionView numberOfItemsInSection:section] + 1) / self.numberOfColumns;
	}
	
	CGFloat height = self.sectionInset.top + rowCount * self.itemHeight + (rowCount - 1) * self.interItemSpacing + self.sectionInset.bottom;
	
	_collectionViewContentSize = CGSizeMake(self.collectionView.bounds.size.width, height);
	
	// Precalculate attributes
	_layoutAttributes = [self _layoutAttributesForCollectionWithBound:self.collectionView.bounds];
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSMutableArray *elements = [NSMutableArray array];
	[_layoutAttributes enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *indexPath, UICollectionViewLayoutAttributes *attributes, BOOL *stop) {
		if (CGRectIntersectsRect(attributes.frame, rect)) {
			[elements addObject:attributes];
		} else if (elements.count > 0) {
			*stop = YES;
		}
	}];
	return elements.copy;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return _layoutAttributes[indexPath];
}

- (CGSize)collectionViewContentSize
{
	return _collectionViewContentSize;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
	return self.collectionView.bounds.size.width != newBounds.size.width;
}

- (void)prepareForAnimatedBoundsChange:(CGRect)oldBounds {
	_preAnimationLayoutAttributes = [self _layoutAttributesForCollectionWithBound:oldBounds];
}

- (void)finalizeAnimatedBoundsChange {
	_preAnimationLayoutAttributes = nil;
}

- (UICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	return _preAnimationLayoutAttributes[itemIndexPath];
}

- (UICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
	return _preAnimationLayoutAttributes[itemIndexPath];
}

- (NSDictionary *)_layoutAttributesForCollectionWithBound:(CGRect)bounds {
	// Calculate item width
	CGFloat itemFullWidth = (
					bounds.size.width
										- self.sectionInset.left
										- self.sectionInset.right
										+ self.interItemSpacing) / self.numberOfColumns;
	
	// Generate attributes and chace them
	NSMutableDictionary *attributesDictionary = [NSMutableDictionary dictionary];
	UICollectionViewLayoutAttributes *attributes;
	NSInteger itemsCount;
	NSIndexPath *itemPath;
	for (NSInteger section = 0; section < self.collectionView.numberOfSections; ++section) {
		itemsCount = [self.collectionView numberOfItemsInSection:section];
		for (NSInteger item = 0; item < itemsCount; ++item) {
			itemPath = [NSIndexPath indexPathForItem:item inSection:section];
			attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:itemPath];
			
			attributes.frame = CGRectMake(
																		floorf(self.sectionInset.left + itemFullWidth * (item % self.numberOfColumns)),
																		floorf(self.sectionInset.top + (self.itemHeight + self.interItemSpacing) * (item / self.numberOfColumns)),
																		floorf(itemFullWidth - self.interItemSpacing),
																		self.itemHeight);
			
			[attributesDictionary setObject:attributes forKey:itemPath];
		}
	}
	return attributesDictionary.copy;
}

@end
