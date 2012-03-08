//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "ACProjectFileSystemItem+Internal.h"
#import "ACProjectFolder.h"
#import "NSURL+Utilities.h"

static NSString * const ProjectsDirectoryName = @"LocalProjects";
static NSString * const _rootFolderName = @"RootFolder";


@implementation ACProject

@synthesize rootFolder = _rootFolder;

- (ACProjectFolder *)rootFolder
{
    if (self.documentState == UIDocumentStateClosed)
        return nil;
    if (!_rootFolder)
    {
        _rootFolder = [[ACProjectFolder alloc] initWithName:_rootFolderName parent:nil contents:nil];
    }
    return _rootFolder;
}

#pragma mark - UIDocument

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSFileWrapper *fileWrapper = (NSFileWrapper *)contents;
    
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:nil];
    return fileWrapper;
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    NSLog(@">>>>>>>>>>>>>>>>> %@", error);
}

#pragma mark - Class Methods

+ (NSURL *)projectsURL
{
    static NSURL *_projectsURL = nil;
    if (!_projectsURL)
        _projectsURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:ProjectsDirectoryName isDirectory:YES];
    return _projectsURL;
}

+ (void)createProjectWithName:(NSString *)name importArchiveURL:(NSURL *)archiveURL completionHandler:(void (^)(ACProject *))completionHandler
{
    // Ensure that projects URL exists
    [[NSFileManager new] createDirectoryAtURL:[self projectsURL] withIntermediateDirectories:YES attributes:nil error:NULL];
    
    // Create the project
    NSURL *projectURL = [[self projectsURL] URLByAppendingPathComponent:[name stringByAppendingPathExtension:@"acproj"]];
    ACProject *project = [[ACProject alloc] initWithFileURL:projectURL];
    [project saveToURL:projectURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        // Inform the completion handler
        if (completionHandler)
            completionHandler(success ? project : nil);
    }];
}

@end
