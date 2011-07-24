//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateInternal.h"
#import "ACProject.h"

@interface ACState ()

/// The projects list
@property (nonatomic, strong) NSMutableArray *projects;

/// Dictionary with project names as keys and project document objects as values
@property (nonatomic, strong) NSMutableDictionary *projectDocuments;

/// Return the path of the application documents directory
- (NSString *)applicationDocumentsDirectory;

/// Scans the application document directory for new projects
- (void)scanForProjects;

/// Renames a project
- (void)setName:(NSString *)name forProjectAtIndex:(NSUInteger)index;

/// Returns the name of a project in the projects list
- (NSString *)nameOfProjectAtIndex:(NSUInteger)index;

/// Sets the index of a project in the projects list
/// The project is inserted at the set index, other projects are shuffled
- (void)setIndex:(NSUInteger)newIndex forProjectAtIndex:(NSUInteger)oldIndex;

/// Returns the color of a project
- (UIColor *)colorForProjectAtIndex:(NSUInteger)index;

/// Sets the color of a project
- (void)setColor:(UIColor *)color forProjectAtIndex:(NSUInteger)index;

@end

@implementation ACState

#pragma mark - Application Level

@synthesize projects = _projects;
@synthesize projectDocuments = _projectDocuments;

+ (ACState *)sharedState
{
    static ACState *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedState = [[self alloc] init];
        sharedState->_projectDocuments = [NSMutableDictionary dictionary];
    });
    return sharedState;
}

- (void)loadState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self willChangeValueForKey:@"allProjects"];
    self.projects = [NSMutableArray arrayWithArray:[defaults arrayForKey:@"projects"]];
    [self scanForProjects];
    [self didChangeValueForKey:@"allProjects"];
}

- (void)saveState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[self.projects copy] forKey:@"projects"];
    [defaults synchronize];
}

- (NSString *)applicationDocumentsDirectory
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (void)scanForProjects
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSArray *projectPaths = [fileManager contentsOfDirectoryAtPath:self.applicationDocumentsDirectory error:NULL];
    for (NSString *path in projectPaths)
    {
        if (![[path pathExtension] isEqualToString:ACProjectBundleExtension])
            continue;
        NSString *name = [path stringByDeletingPathExtension];
        if ([self indexOfProjectWithName:name] == NSNotFound)
             [self.projects addObject:[NSDictionary dictionaryWithObjectsAndKeys:name, @"name", nil, @"color" , nil]];
    }
}


#pragma mark - Project Level

- (NSOrderedSet *)allProjects
{
    NSMutableOrderedSet *allProjects = [NSMutableOrderedSet orderedSetWithCapacity:[self.projects count]];
    for (NSDictionary *project in self.projects)
        [allProjects addObject:[ACStateProject projectProxyForProjectWithName:[project objectForKey:@"name"]]];
    return allProjects;
}

- (void)setName:(NSString *)newName forProjectWithName:(NSString *)oldName
{
    ECASSERT(oldName && newName && [self indexOfProjectWithName:oldName] != NSNotFound);
    [self setName:newName forProjectAtIndex:[self indexOfProjectWithName:oldName]];
}

- (void)setName:(NSString *)name forProjectAtIndex:(NSUInteger)index
{
    ECASSERT(name && [self indexOfProjectWithName:name] == NSNotFound);
    ECASSERT(index < [self.projects count]);
    NSDictionary *project = [self.projects objectAtIndex:index];
    NSString *oldName = [project objectForKey:@"name"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectWillRenameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
    project = [NSDictionary dictionaryWithObjectsAndKeys:name, @"name", [project objectForKey:@"color"], @"color", nil];
    [self.projects replaceObjectAtIndex:index withObject:project];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectProxyRenameCommand object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectDidRenameNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:oldName, @"oldName", name, @"newName", nil]];
}

- (NSUInteger)indexOfProjectWithName:(NSString *)name
{
    ECASSERT(name);
    NSUInteger index = 0;
    for (NSDictionary *project in self.projects)
        if ([[project objectForKey:@"name"] isEqualToString:name])
            return index;
        else
            ++index;
    return NSNotFound;
}

- (NSString *)nameOfProjectAtIndex:(NSUInteger)index
{
    ECASSERT(index < [self.projects count]);
    return [[self.projects objectAtIndex:index] objectForKey:@"name"];
}

- (void)setIndex:(NSUInteger)index forProjectWithName:(NSString *)name
{
    ECASSERT(name && [self indexOfProjectWithName:name] != NSNotFound);
    [self setIndex:index forProjectAtIndex:[self indexOfProjectWithName:name]];
}

- (void)setIndex:(NSUInteger)newIndex forProjectAtIndex:(NSUInteger)oldIndex
{
    ECASSERT(oldIndex < [self.projects count]);
    ECASSERT(newIndex < [self.projects count]);
    if (newIndex == oldIndex)
        return;
    NSDictionary *project = [self.projects objectAtIndex:oldIndex];
    NSString *name = [project objectForKey:@"name"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectPropertiesWillChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:name , @"name", [NSArray arrayWithObject:@"index"], @"propertyKeys", nil]];
    [self.projects removeObjectAtIndex:oldIndex];
    [self.projects insertObject:project atIndex:newIndex];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectPropertiesDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:name , @"name", [NSArray arrayWithObject:@"index"], @"propertyKeys", nil]];
}

- (UIColor *)colorForProjectWithName:(NSString *)name
{
    ECASSERT(name && [self indexOfProjectWithName:name] != NSNotFound);
    return [self colorForProjectAtIndex:[self indexOfProjectWithName:name]];
}

- (UIColor *)colorForProjectAtIndex:(NSUInteger)index
{
    ECASSERT(index < [self.projects count]);
    return [[self.projects objectAtIndex:index] objectForKey:@"color"];
}

- (void)setColor:(UIColor *)color forProjectWithName:(NSString *)name
{
    ECASSERT(name && [self indexOfProjectWithName:name] != NSNotFound);
    [self setColor:color forProjectAtIndex:[self indexOfProjectWithName:name]];
}

- (void)setColor:(UIColor *)color forProjectAtIndex:(NSUInteger)index
{
    ECASSERT(index < [self.projects count]);
    NSDictionary *project = [self.projects objectAtIndex:index];
    NSString *name = [project objectForKey:@"name"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectPropertiesWillChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:name , @"name", [NSArray arrayWithObject:@"color"], @"propertyKeys", nil]];
    project = [NSDictionary dictionaryWithObjectsAndKeys:[project objectForKey:@"name"], @"name", color, @"color", nil];
    [self.projects replaceObjectAtIndex:index withObject:project];
    [[NSNotificationCenter defaultCenter] postNotificationName:ACProjectPropertiesDidChangeNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:name , @"name", [NSArray arrayWithObject:@"color"], @"propertyKeys", nil]];
}

- (void)insertProjectWithName:(NSString *)name color:(UIColor *)color atIndex:(NSUInteger)index
{
    ECASSERT(name && [self indexOfProjectWithName:name] == NSNotFound);
    if (index == NSNotFound)
        index = [self.projects count];
    ACStateProject *proxy = [ACStateProject projectProxyForProjectWithName:name];
    [self willChangeValueForKey:@"allProjects" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:proxy]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"allProjects"];
    [self.projects insertObject:[NSDictionary dictionaryWithObjectsAndKeys:name, @"name", color, @"color", nil] atIndex:index];
    [self didChangeValueForKey:@"allProjects" withSetMutation:NSKeyValueUnionSetMutation usingObjects:[NSSet setWithObject:proxy]];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"allProjects"];
}

- (void)deleteProjectWithName:(NSString *)name
{
    ECASSERT(name && [self indexOfProjectWithName:name] != NSNotFound);
    [self deleteProjectAtIndex:[self indexOfProjectWithName:name]];
}

- (void)deleteProjectAtIndex:(NSUInteger)index
{
    ECASSERT(index < [self.projects count]);
    ACStateProject *proxy = [ACStateProject projectProxyForProjectWithName:[self nameOfProjectAtIndex:index]];
    [self willChangeValueForKey:@"allProjects" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:proxy]];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"allProjects"];
    [self.projects removeObjectAtIndex:index];
    [self didChangeValueForKey:@"allProjects" withSetMutation:NSKeyValueMinusSetMutation usingObjects:[NSSet setWithObject:proxy]];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:[NSIndexSet indexSetWithIndex:index] forKey:@"allProjects"];
}

- (void)openProjectWithName:(NSString *)name withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ACProject *projectDocument = [self.projectDocuments objectForKey:name];
    if (!projectDocument)
        projectDocument = [[ACProject alloc] initWithFileURL:[NSURL fileURLWithPath:[[self.applicationDocumentsDirectory stringByAppendingPathComponent:name] stringByAppendingPathExtension:ACProjectBundleExtension]]];
    [projectDocument openWithCompletionHandler:completionHandler];
}

- (void)closeProjectWithName:(NSString *)name withCompletionHandler:(void (^)(BOOL))completionHandler
{
    ECASSERT([self.projectDocuments objectForKey:name]);
    [[self.projectDocuments objectForKey:name] closeWithCompletionHandler:completionHandler];
}

@end
