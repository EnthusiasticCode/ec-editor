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

static NSString * const _projectsFolderName = @"LocalProjects";
static NSString * const _contentsFolderName = @"Contents";


@implementation ACProject

@synthesize contentsFolder = _contentsFolder;

- (ACProjectFolder *)rootFolder
{
    if (self.documentState == UIDocumentStateClosed)
        return nil;
    if (!_contentsFolder)
    {
        _contentsFolder = [[ACProjectFolder alloc] initWithName:_contentsFolderName parent:nil contents:nil];
    }
    return _contentsFolder;
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
        _projectsURL = [[NSURL applicationLibraryDirectory] URLByAppendingPathComponent:_projectsFolderName isDirectory:YES];
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
