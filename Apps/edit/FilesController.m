//
//  ProjectController.m
//  edit
//
//  Created by Uri Baghin on 1/21/11.
//  Copyright 2011 _MyCompanyName_. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "FilesController.h"
#import "Project.h"
#import "Node.h"
#import "File.h"
#import "FileController.h"
#import "EditorController.h"
#import "Client.h"

static NSString *const DefaultIdentifier = @"Default";

static NSString *const FileSegueIdentifier = @"File";

@implementation FilesController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark -
#pragma mark UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[[Client sharedClient].currentProject children] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DefaultIdentifier];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DefaultIdentifier];
    }
    cell.textLabel.text = [[[[Client sharedClient].currentProject children] objectAtIndex:indexPath.row] name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Project *project = [Client sharedClient].currentProject;
    [Client sharedClient].currentFile = [[project children] objectAtIndex:indexPath.row];
}

@end
