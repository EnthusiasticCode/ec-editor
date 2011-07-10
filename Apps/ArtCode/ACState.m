//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "NSFileManager(ECAdditions).h"
#import "ACStateProject.h"

@implementation ACState

@synthesize projects = _projects;

- (NSFileManager *)fileManager
{
    static NSFileManager *fileManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fileManager = [[NSFileManager alloc] init];
    });
    return fileManager;
}

- (NSOrderedSet *)projects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableOrderedSet *projects = [[NSMutableOrderedSet alloc] init];
    for (NSDictionary *dictionary in [defaults arrayForKey:@"projects"]) {
        ACStateProject *project = [[ACStateProject alloc] init];
        project.path = [dictionary objectForKey:@"path"];
        project.name = [project.path lastPathComponent];
        project.color = [NSKeyedUnarchiver unarchiveObjectWithData:[dictionary objectForKey:@"color"]];
        [projects addObject:project];
    }
    return projects;
}

+ (ACState *)sharedState
{
    static ACState *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedState = [[self alloc] init];
    });
    return sharedState;
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSArray *)projectBundlesInApplicationDocumentsDirectory
{
    return [self.fileManager subpathsOfDirectoryAtPath:[self applicationDocumentsDirectory] withExtensions:[NSArray arrayWithObject:@"acproj"] options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:NO skipDirectories:NO error:NULL];
}

- (void)scanForProjects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *projectPaths = [self projectBundlesInApplicationDocumentsDirectory];
    NSMutableArray *projects = [NSMutableArray array];
    for (NSString *path in projectPaths) {
        [projects addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSKeyedArchiver archivedDataWithRootObject:[UIColor redColor]], @"color" , nil]];
    }
    [defaults setObject:projects forKey:@"projects"];
    [defaults synchronize];
}

@end
