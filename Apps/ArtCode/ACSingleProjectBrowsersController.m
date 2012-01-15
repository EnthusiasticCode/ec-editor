//
//  ACBottomTabBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSingleProjectBrowsersController.h"
#import "ACProject.h"
#import "ACTab.h"
#import "ACTopBarTitleControl.h"

#import "AppStyle.h"
#import "ACColorSelectionControl.h"

#import "ACFileTableController.h"

@implementation ACSingleProjectBrowsersController {
    UIButton *_projectColorLabelButton;
    UIPopoverController *_projectColorLabelPopover;
}

#pragma mark - Properties

@synthesize tab;

- (NSArray *)toolbarItems
{
    return self.selectedViewController.toolbarItems;
}

- (void)setToolbarItems:(NSArray *)toolbarItems
{
    self.selectedViewController.toolbarItems = toolbarItems;
}

+ (NSSet *)keyPathsForValuesAffectingToolbarItems
{
    return [NSSet setWithObject:@"selectedViewController.toolbarItems"];
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

- (void)loadView
{
    [super loadView];
    
    self.editButtonItem.title = @"";
    self.editButtonItem.image = [UIImage imageNamed:@"topBarItem_Edit"];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self willChangeValueForKey:@"editing"];
    
    [super setEditing:editing animated:animated];
    self.editButtonItem.title = @"";
    
    [self.selectedViewController setEditing:editing animated:animated];
    
    [self didChangeValueForKey:@"editing"];
}

#pragma mark - Single tab content controller protocol methods

- (void)_projectColorLabelSelectionAction:(id)sender
{
    ACProject *project = [ACProject projectWithURL:self.tab.currentURL];
    project.labelColor = [(ACColorSelectionControl *)sender selectedColor];
    [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:project.labelColor] forState:UIControlStateNormal];
    [_projectColorLabelPopover dismissPopoverAnimated:YES];
}

- (void)_projectColorLabelAction:(id)sender
{
    if (!_projectColorLabelPopover)
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
        [colorControl addTarget:self action:@selector(_projectColorLabelSelectionAction:) forControlEvents:UIControlEventTouchUpInside];
        
        UIViewController *viewController = [UIViewController new];
        viewController.contentSizeForViewInPopover = CGSizeMake(145, 90);
        viewController.view = colorControl;
        
        _projectColorLabelPopover = [[UIPopoverController alloc] initWithContentViewController:viewController];
    }
    
    [_projectColorLabelPopover presentPopoverFromRect:[sender frame] inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (BOOL)singleTabController:(ACSingleTabController *)singleTabController setupDefaultToolbarTitleControl:(ACTopBarTitleControl *)titleControl
{
    BOOL isRoot = NO;
    NSString *projectName = [ACProject projectNameFromURL:self.tab.currentURL isProjectRoot:&isRoot];
    if (!isRoot)
    {
        return NO; // default behaviour
    }
    else
    {
        ACProject *project = [ACProject projectWithName:projectName];
        
        if (!_projectColorLabelButton)
        {
            _projectColorLabelButton  = [UIButton buttonWithType:UIButtonTypeCustom];
            [_projectColorLabelButton addTarget:self action:@selector(_projectColorLabelAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:project.labelColor] forState:UIControlStateNormal];
        [_projectColorLabelButton sizeToFit];
        
        [titleControl setTitleFragments:[NSArray arrayWithObjects:_projectColorLabelButton, projectName, nil] 
                        selectedIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)]];
    }
    return YES;
}

#pragma mark - Opening Browser

- (UIViewController *)_viewControllerWithClass:(Class)class
{
    for (UIViewController *controller in self.viewControllers) {
        if ([controller isKindOfClass:class])
            return controller;
    }
    return nil;
}

- (void)openFileBrowserWithURL:(NSURL *)url
{
    ACFileTableController *tableBrowser = (ACFileTableController *)[self _viewControllerWithClass:[ACFileTableController class]];
    if (!tableBrowser)
        return;
    
    tableBrowser.directory = url;
    tableBrowser.tab = tab;
    
    self.selectedViewController = tableBrowser;
}

@end
