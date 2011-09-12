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

@implementation ACNewProjectFromTemplateController

@synthesize newProjectFromTemplate;

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
    NSString *projectName;
    for (NSUInteger projectNumber = 0; YES; ++projectNumber)
    {
        projectName = [@"Project " stringByAppendingString:[NSString stringWithFormat:@"%d", projectNumber]];
        if ([[ACProjectDocumentsList sharedList] projectDocumentWithName:projectName])
            continue;
        break;
    }
    [[ACProjectDocumentsList sharedList] addNewProjectWithName:projectName atIndex:NSNotFound fromTemplate:nil withCompletionHandler:^(BOOL success) {
        NSString *message = nil;
        if (success)
            message = [@"Added new project: " stringByAppendingString:projectName];
        else
            message = @"Add project failed";
        [[ECBezelAlert centerBezelAlert] addAlertMessageWithText:message image:nil displayImmediatly:NO];
        
    }];
}

@end
