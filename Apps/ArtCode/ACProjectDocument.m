//
//  ACProjectDocument.m
//  ArtCode
//
//  Created by Uri Baghin on 8/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ACProjectDocument.h"
#import "ACProject.h"

static NSString * const ACProjectContentDirectory = @"Content";

@implementation ACProjectDocument

@synthesize project = _project;

- (ACProject *)project
{
    if (self.documentState == UIDocumentStateClosed)
        return nil;
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
        _project.fileURL = [self.fileURL URLByAppendingPathComponent:ACProjectContentDirectory];
        // TODO: when URL of project is changed, and the document is moved, project's fileURL should be updated
    }
    return _project;
}

- (NSString *)localizedName
{
    // TODO: this property is built in UIDocument, but doesn't seem to work, at least on non-open documents
    return [[[self.fileURL lastPathComponent] stringByDeletingPathExtension] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

+ (NSSet *)keyPathsForValuesAffectingName
{
    return [NSSet setWithObject:@"fileURL"];
}

+ (NSString *)persistentStoreName
{
    return @"acproject.db";
}

- (NSDictionary *)persistentStoreOptions
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
}

@end
