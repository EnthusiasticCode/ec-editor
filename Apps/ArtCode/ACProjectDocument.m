//
//  ACProjectDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectDocument.h"
#import "ACProject.h"
#import "ACURL.h"

void * ACProjectDocumentProjectURLObserving;

@implementation ACProjectDocument

@synthesize project = _project;
@synthesize projectURL = _projectURL;

// TODO: handle the pass through of URL and fileURL to the core data project object more gracefully

- (ACProject *)project
{
    if (!_project)
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Project" inManagedObjectContext:self.managedObjectContext]];
        NSArray *projects = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
        if ([projects count] > 1)
            // TODO: fix the core data file by merging projects
            ECASSERT(NO); // core data file broken, more than 1 project
        if (![projects count])
            _project = [NSEntityDescription insertNewObjectForEntityForName:@"Project" inManagedObjectContext:self.managedObjectContext];
        else
            _project = [projects objectAtIndex:0];
        ECASSERT([self.projectURL isACURL]);
        _project.URL = self.projectURL;
        [_project setPrimitiveValue:[self.projectURL ACProjectName] forKey:@"name"];
        _project.fileURL = [self.fileURL URLByDeletingPathExtension];
    }
    ECASSERT(_project); // should never return nil
    return _project;
}

- (void)setProjectURL:(NSURL *)projectURL
{
    if (projectURL == _projectURL)
        return;
    [self willChangeValueForKey:@"projectURL"];
    _projectURL = projectURL;
    if (_project)
    {
        [_project willChangeValueForKey:@"name"];
        _project.URL = projectURL;
        [_project setPrimitiveValue:[projectURL ACProjectName] forKey:@"name"];
        _project.fileURL = [self.fileURL URLByDeletingPathExtension];
        [_project didChangeValueForKey:@"name"];
    }
    [self didChangeValueForKey:@"projectURL"];
}

+ (NSString *)persistentStoreName
{
    return @"acproject.db";
}

- (NSDictionary *)persistentStoreOptions
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
}

- (NSManagedObjectModel *)managedObjectModel
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Project" withExtension:@"momd"];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (id)objectWithURL:(NSURL *)URL
{
    if ([URL isEqual:self.projectURL])
        return self.project;
    if (![URL isDescendantOfACURL:self.projectURL])
        return nil;
    NSArray *pathComponents = [URL pathComponents];
    NSUInteger pathComponentsCount = [pathComponents count];
    ACNode *node = self.project;
    for (NSUInteger currentPathComponent = 2; currentPathComponent < pathComponentsCount; ++currentPathComponent)
        node = [node childWithName:[pathComponents objectAtIndex:currentPathComponent]];
    return node;
}

- (void)deleteObjectWithURL:(NSURL *)URL
{
    id object = [self objectWithURL:URL];
    [self.managedObjectContext deleteObject:object];
}

- (void)handleError:(NSError *)error userInteractionPermitted:(BOOL)userInteractionPermitted
{
    // TODO: handle errors gracefully
    // for now, just debug them manually by checking [error localizedDescription]
    // NOTE: do not delete this even if it stays empty, because UIDocument fails VERY silently otherwise
    ECASSERT(NO);
}

@end
