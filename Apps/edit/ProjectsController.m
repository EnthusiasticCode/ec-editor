//
//  ProjectBrowser.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectsController.h"
#import <ECFoundation/NSFileManager(ECAdditions).h>
#import "FilesController.h"

static const NSString *DefaultReuseIdentifier = @"Default";

@interface ProjectsController ()
@property (nonatomic, strong) NSFileManager *fileManager;
- (NSArray *)_contentsOfRootFolder;
@end

@implementation ProjectsController

@synthesize rootController = _rootController;
@synthesize fileManager = _fileManager;

- (NSFileManager *)fileManager
{
    if (!_fileManager)
        _fileManager = [[NSFileManager alloc] init];
    return _fileManager;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (NSArray *)_contentsOfRootFolder
{
    return [self.fileManager contentsOfDirectoryAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] withExtensions:nil options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:YES skipDirectories:NO error:NULL];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *file = [tableView dequeueReusableCellWithIdentifier:(NSString *)DefaultReuseIdentifier];
    if (!file)
    {
        file = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:(NSString *)DefaultReuseIdentifier];
    }
    file.textLabel.text = [[[self _contentsOfRootFolder] objectAtIndex:(indexPath.row)] lastPathComponent];
    return file;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self _contentsOfRootFolder] count];
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSString *projectFolder = [self.folder stringByAppendingPathComponent:[[self contentsOfFolder] objectAtIndex:indexPath.row]];
//    FilesController *projectController = ((AppController *)self.navigationController).projectController;
//    [projectController loadProject:projectFolder];
//    [self.navigationController pushViewController:projectController animated:YES];
//}

@end
