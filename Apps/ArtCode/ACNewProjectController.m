//
//  ACNewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectController.h"
#import "ACNewProjectNavigationController.h"

#import <ECFoundation/NSURL+ECAdditions.h>
#import <ECFoundation/ECDirectoryPresenter.h>
#import <ECUIKit/ECBezelAlert.h>

#import "ACColorSelectionControl.h"

@implementation ACNewProjectController {
    UIViewController *changeColorController;
}

@synthesize projectColorButton;
@synthesize projectNameTextField;

- (void)viewDidUnload {
    [self setProjectNameTextField:nil];
    [self setProjectColorButton:nil];
    [super viewDidUnload];
}

- (void)_selectColorAction:(ACColorSelectionControl *)sender
{
//    sender.selectedColor
}

- (IBAction)changeColorAction:(id)sender
{
    if (!changeColorController)
    {
        ACColorSelectionControl *colorSelectionControl = [[ACColorSelectionControl alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        [colorSelectionControl addTarget:self action:@selector(_selectColorAction:) forControlEvents:UIControlEventTouchUpInside];
        colorSelectionControl.colorCellsMargin = 2;
        colorSelectionControl.columns = 3;
        colorSelectionControl.rows = 2;
        colorSelectionControl.colors = [NSArray arrayWithObjects:
                               [UIColor colorWithRed:255./255. green:106./255. blue:89./255. alpha:1], 
                               [UIColor colorWithRed:255./255. green:184./255. blue:62./255. alpha:1], 
                               [UIColor colorWithRed:237./255. green:233./255. blue:68./255. alpha:1],
                               [UIColor colorWithRed:168./255. green:230./255. blue:75./255. alpha:1],
                               [UIColor colorWithRed:93./255. green:157./255. blue:255./255. alpha:1],
                               [UIColor blackColor], nil];

        changeColorController = [UIViewController new];
        changeColorController.view = colorSelectionControl;
        changeColorController.contentSizeForViewInPopover = CGSizeMake(300, 200);
    }
    [self.navigationController pushViewController:changeColorController animated:YES];
    [[(ACNewProjectNavigationController *)self.navigationController popoverController] setPopoverContentSize:CGSizeMake(300, 200) animated:YES];
}

- (IBAction)createProjectAction:(id)sender
{
    NSString *projectName = self.projectNameTextField.text;
    if ([projectName length] == 0)
    {
        // TODO alert for missing text name or already existing
    }
    
    ECFileCoordinator *fileCoordinator = [[ECFileCoordinator alloc] initWithFilePresenter:nil];
    NSURL *projectsDirectory = [(ACNewProjectNavigationController *)self.navigationController projectsDirectory];
    [fileCoordinator coordinateWritingItemAtURL:[[projectsDirectory URLByAppendingPathComponent:projectName] URLByAppendingPathExtension:@"weakpkg"] options:0 error:NULL byAccessor:^(NSURL *newURL) {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        [fileManager createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
    }];
    
    // TODO manage error
    
    [[(ACNewProjectNavigationController *)self.navigationController popoverController] dismissPopoverAnimated:YES];
    [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"New project created" image:nil displayImmediatly:YES];
}

@end