//
//  ProjectBrowser.m
//  edit
//
//  Created by Uri Baghin on 3/26/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ProjectsController.h"
#import "RootController.h"
#import <ECFoundation/NSFileManager(ECAdditions).h>
#import "FilesController.h"
#import "ECStoryboardFloatingSplitSidebarSegue.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat TransitionDuration = 0.15;

static const NSString *DefaultReuseIdentifier = @"Default";

static const NSString *FilesSegueIdentifier = @"Files";

@interface ProjectsController ()
@property (nonatomic, strong) NSFileManager *fileManager;
- (NSString *)_rootFolder;
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

- (NSString *)_rootFolder
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSArray *)_contentsOfRootFolder
{
    return [self.fileManager contentsOfDirectoryAtPath:[self _rootFolder] withExtensions:nil options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:YES skipDirectories:NO error:NULL];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([identifier isEqualToString:(NSString *)FilesSegueIdentifier])
    {
        [segue.destinationViewController loadProject:[[self _rootFolder] stringByAppendingPathComponent:[[self _contentsOfRootFolder] objectAtIndex:[self.tableView indexPathForSelectedRow].row]]];
        CATransition *transition = [CATransition animation];
        transition.duration = TransitionDuration;
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFromTop;
        [(ECStoryboardFloatingSplitSidebarSegue *)segue setTransition:transition];
    }
    [self.rootController prepareForSegue:segue sender:sender];
}

@end
