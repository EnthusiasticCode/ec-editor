//
//  ProjectListItem.m
//  ArtCode
//
//  Created by Uri Baghin on 9/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectListItem.h"
#import "ACApplication.h"
#import "ACProjectDocument.h"
#import "ACProject.h"
#import "ACURL.h"

@interface ACProjectListItem ()
@property (nonatomic, strong, readonly) ACProjectDocument *document;
- (ACProject *)project;
@end

@implementation ACProjectListItem

@dynamic tag;
@dynamic application;

@synthesize document = _document;

- (NSURL *)projectURL
{
    return [NSURL URLWithString:[self primitiveValueForKey:@"projectURL"]];
}

- (void)setProjectURL:(NSURL *)projectURL
{
    [self willChangeValueForKey:@"projectURL"];
    [self setPrimitiveValue:[projectURL absoluteString] forKey:@"projectURL"];
    [self didChangeValueForKey:@"projectURL"];
}

- (NSString *)name
{
    return [self.projectURL ACObjectName];
}

- (UIManagedDocument *)document
{
    if (!self.projectURL)
        return nil;
    if (!_document)
        _document = [[ACProjectDocument alloc] initWithFileURL:[self.projectURL ACObjectFileURL]];
    ECASSERT(_document);
    return _document;
}

- (void)loadProjectWithCompletionHandler:(void (^)(ACProject *))completionHandler
{
    if (!self.document)
        if (completionHandler)
            completionHandler(nil);
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *projectDocumentURL = [self.projectURL ACObjectFileURL];
    if (self.document.documentState & UIDocumentStateClosed)
    {
        if ([fileManager fileExistsAtPath:projectDocumentURL.path])
            [self.document openWithCompletionHandler:^(BOOL success) {
                if (!success)
                    ECASSERT(NO); // TODO: error handling
                if (completionHandler)
                    completionHandler(self.project);
            }];
        else
        {
            [fileManager createDirectoryAtURL:[projectDocumentURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
            [self.document saveToURL:projectDocumentURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                if (!success)
                    ECASSERT(NO); // TODO: error handling
                if (completionHandler)
                    completionHandler(self.project);
            }];
        }
    }
    else
        if (completionHandler)
            completionHandler(self.project);
}

- (ACProject *)project
{
    ACProject *project = nil;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.document.managedObjectContext]];
    NSArray *projects = [self.document.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    if ([projects count] > 1)
        // TODO: fix the core data file by merging projects
        ECASSERT(NO); // core data file broken, more than 1 project
    if (![projects count])
        project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.document.managedObjectContext];
    else
        project = [projects objectAtIndex:0];
    ECASSERT(project); // should never return nil
    project.projectListItem = self;
    return project;
}

@end
