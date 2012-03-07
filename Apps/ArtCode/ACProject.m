//
//  ACProject.m
//  ArtCode
//
//  Created by Uri Baghin on 3/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ACProject.h"
#import "NSURL+Utilities.h"

static NSString * const ProjectsDirectoryName = @"LocalProjects";


@implementation ACProject

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

@end
