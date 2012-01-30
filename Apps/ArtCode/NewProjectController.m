//
//  NewProjectPopoverController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NewProjectController.h"
#import "NewProjectNavigationController.h"

#import "BezelAlert.h"

#import "ArtCodeProject.h"
#import "AppStyle.h"
#import "ColorSelectionControl.h"
#import "ArtCodeTab.h"

@implementation NewProjectController {
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

- (void)_selectColorAction:(ColorSelectionControl *)sender
{
    projectColor = sender.selectedColor;
    [self.projectColorButton setImage:[UIImage styleProjectLabelImageWithSize:self.projectColorButton.bounds.size color:projectColor] forState:UIControlStateNormal];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)changeColorAction:(id)sender
{
    if (!changeColorController)
    {
        ColorSelectionControl *colorSelectionControl = [[ColorSelectionControl alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
        [colorSelectionControl addTarget:self action:@selector(_selectColorAction:) forControlEvents:UIControlEventTouchUpInside];

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
    if ([ArtCodeProject projectWithNameExists:projectName])
    {
        self.descriptionLabel.text = @"A project with this name already exists, use a different name.";
        return;
    }
    
    ArtCodeProject *project = [ArtCodeProject projectWithName:projectName];
    if (projectColor)
        project.labelColor = projectColor;
    [project flush];
    
    [[(NewProjectNavigationController *)self.navigationController popoverController] dismissPopoverAnimated:YES];
    [[BezelAlert defaultBezelAlert] addAlertMessageWithText:@"New project created" image:nil displayImmediatly:YES];
    [[(NewProjectNavigationController *)self.navigationController parentController].tab pushURL:project.URL];
}

@end