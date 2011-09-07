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

static NSString * const ACProjectContentDirectory = @"Content";

@implementation ACProjectDocument

@synthesize project = _project;
@synthesize projectURL = _projectURL;

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
        _project.fileURL = [self.fileURL URLByAppendingPathComponent:ACProjectContentDirectory];
    }
    return _project;
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
