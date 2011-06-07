//
//  GroupController.m
//  edit
//
//  Created by Uri Baghin on 5/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupController.h"
#import "FileController.h"
#import "AppController.h"
#import "ProjectController.h"
#import "Node.h"

@implementation GroupController
@synthesize group = _group;

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.group.children count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.text = [[[self.group orderedChildren] objectAtIndex:indexPath.row] name];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self loadNode:[[self.group orderedChildren] objectAtIndex:indexPath.row]];
}

- (void)loadNode:(Node *)node
{
    if (![node.type isEqualToString:@"Group"])
        [((AppController *)self.navigationController).projectController loadFile:(File *)node];
    else
    {
        GroupController *groupController = [[[GroupController alloc] init] autorelease];
        groupController.group = node;
        [self.navigationController pushViewController:groupController animated:YES];
    }
}

@end
