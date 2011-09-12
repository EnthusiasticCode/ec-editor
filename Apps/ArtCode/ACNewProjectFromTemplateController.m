//
//  ACPopoverNewProjectFromTemplateController.m
//  ArtCode
//
//  Created by Uri Baghin on 9/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACNewProjectFromTemplateController.h"
#import "ACProjectDocumentsList.h"
#import "ECBezelAlert.h"
#import "ACNewProjectPopoverController.h"

@implementation ACNewProjectFromTemplateController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Default";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = @"Blank project";
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ECASSERT([(ACNewProjectPopoverController *)self.navigationController newProjectFromTemplate]);
    [(ACNewProjectPopoverController *)self.navigationController newProjectFromTemplate](nil);
}

@end
