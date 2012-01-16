//
//  ACNewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectController.h"
#import "ACNewProjectNavigationController.h"

#import <ECUIKit/ECBezelAlert.h>

#import "ACProject.h"
#import "AppStyle.h"
#import "ACColorSelectionControl.h"
#import "ACTab.h"

@implementation ACNewProjectController {
    UIViewController *changeColorController;

    UIColor *projectColor;
}

@synthesize projectColorButton;
@synthesize projectNameTextField;
@synthesize descriptionLabel;


- (void)viewDidUnload {
    [self setProjectNameTextField:nil];
    [self setProjectColorButton:nil];
    [self setDescriptionLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.projectColorButton setImage:[UIImage styleProjectLabelImageWithSize:self.projectColorButton.bounds.size color:projectColor] forState:UIControlStateNormal];
}

- (void)_selectColorAction:(ACColorSelectionControl *)sender
{
    projectColor = sender.selectedColor;
    [self.projectColorButton setImage:[UIImage styleProjectLabelImageWithSize:self.projectColorButton.bounds.size color:projectColor] forState:UIControlStateNormal];
    [self.navigationController popViewControllerAnimated:YES];
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
                               [UIColor styleForegroundColor], nil];

        changeColorController = [UIViewController new];
        changeColorController.view = colorSelectionControl;
        changeColorController.contentSizeForViewInPopover = CGSizeMake(400, 200);
    }
    [self.navigationController pushViewController:changeColorController animated:YES];
}

- (IBAction)createProjectAction:(id)sender
{
    NSString *projectName = self.projectNameTextField.text;
    if ([projectName length] == 0)
    {
        self.descriptionLabel.text = @"A project name must be specified.";
        return;
    }
    if ([ACProject projectWithNameExists:projectName])
    {
        self.descriptionLabel.text = @"A project with this name already exists, use a different name.";
        return;
    }
    
    ACProject *project = [ACProject projectWithName:projectName];
    if (projectColor)
        project.labelColor = projectColor;
    
    [[(ACNewProjectNavigationController *)self.navigationController popoverController] dismissPopoverAnimated:YES];
    [[ECBezelAlert defaultBezelAlert] addAlertMessageWithText:@"New project created" image:nil displayImmediatly:YES];
    [[(ACNewProjectNavigationController *)self.navigationController parentController].tab performSelector:@selector(pushURL:) withObject:project.URL afterDelay:1];
}

@end