//
//  QuickProjectInfoController.m
//  ArtCode
//
//  Created by Nicola Peduzzi on 28/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "QuickProjectInfoController.h"
#import "QuickBrowsersContainerController.h"

#import "AppStyle.h"
#import "ArtCodeTab.h"
#import "ArtCodeProject.h"

#import "ColorSelectionControl.h"


@interface QuickProjectInfoController ()

- (void)_labelColorChangeAction:(id)sender;

@end


@implementation QuickProjectInfoController

@synthesize projectNameTextField;
@synthesize labelColorSelectionControl;
@synthesize projectFileCountLabel;
@synthesize projectSizeLabel;

#pragma mark - Controller lifecycle

+ (id)new
{
    return [[UIStoryboard storyboardWithName:@"QuickProjectInfo" bundle:nil] instantiateViewControllerWithIdentifier:@"QuickProjectInfo"];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.labelColorSelectionControl.rows = 1;
    self.labelColorSelectionControl.columns = 6;
    [self.labelColorSelectionControl addTarget:self action:@selector(_labelColorChangeAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewDidUnload
{
    [self setProjectNameTextField:nil];
    [self setLabelColorSelectionControl:nil];
    [self setProjectFileCountLabel:nil];
    [self setProjectSizeLabel:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.projectNameTextField.text = [self.quickBrowsersContainerController.tab.currentProject name];
    // TODO add project files and size
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - UITextField Delegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if ([textField.text length] == 0)
        return;
    
    // TODO check that name is ok

    [self.quickBrowsersContainerController.tab.currentProject setName:textField.text];
}

#pragma mark - Private Methods

- (void)_labelColorChangeAction:(id)sender
{
    [self.quickBrowsersContainerController.tab.currentProject setLabelColor:[sender selectedColor]];
}

@end


