//
//  ACBottomTabBarController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 24/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACSingleProjectBrowsersController.h"
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

#pragma mark - Single tab content controller protocol methods

- (void)_projectColorLabelSelectionAction:(id)sender
{
    [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:[(ACColorSelectionControl *)sender selectedColor]] forState:UIControlStateNormal];
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
    // TODO check tab.currentUrl and add button only if in a project root
    if (!_projectColorLabelButton)
    {
        _projectColorLabelButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        [_projectColorLabelButton addTarget:self action:@selector(_projectColorLabelAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    [_projectColorLabelButton setImage:[UIImage styleProjectLabelImageWithSize:CGSizeMake(14, 22) color:[UIColor colorWithRed:255.0/255.0 green:147.0/255.0 blue:30.0/255.0 alpha:1]] forState:UIControlStateNormal];
    [_projectColorLabelButton sizeToFit];
    
    titleControl.titleFragments = [NSArray arrayWithObjects:_projectColorLabelButton, @"title", nil];
    titleControl.selectedTitleFragments = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    // TODO setup project color selection button
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
