//
//  ProjectBrowser.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"
#import <ECFoundation/NSFileManager(ECAdditions).h>
#import "AppController.h"
#import "ProjectController.h"

@interface RootController ()
@property (nonatomic, retain) NSFileManager *fileManager;
@property (nonatomic, retain) NSString *folder;
@end

@implementation RootController

@synthesize fileManager = fileManager_;
@synthesize folder = folder_;

- (NSFileManager *)fileManager
{
    return [NSFileManager defaultManager];
}

- (void)dealloc
{
    self.fileManager = nil;
    self.folder = nil;
    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)browseFolder:(NSString *)folder
{
    self.folder = folder;
}

- (NSArray *)contentsOfFolder
{
    return [self.fileManager contentsOfDirectoryAtPath:self.folder withExtensions:nil options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:YES skipDirectories:NO error:(NSError **)NULL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *file = [tableView dequeueReusableCellWithIdentifier:@"File"];
    if (!file)
    {
        file = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"File"] autorelease];
    }
    file.textLabel.text = [[[self contentsOfFolder] objectAtIndex:(indexPath.row)] lastPathComponent];
    return file;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.folder)
        return 0;
    return [[self contentsOfFolder] count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *projectFolder = [self.folder stringByAppendingPathComponent:[[self contentsOfFolder] objectAtIndex:indexPath.row]];
    ProjectController *projectController = ((AppController *)self.navigationController).projectController;
    [projectController loadProject:projectFolder];
    [self.navigationController pushViewController:projectController animated:YES];
}

@end
