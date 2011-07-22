//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "NSFileManager(ECAdditions).h"

static NSString * const ACProjectBundleExtension = @"acproj";

static NSString * const ACProjectWillRenameNotification = @"ACProjectWillRenameNotification";
static NSString * const ACProjectDidRenameNotification = @"ACProjectDidRenameNotification";
static NSString * const ACProjectPropertiesWillChangeNotification = @"ACProjectPropertiesWillChangeNotification";
static NSString * const ACProjectPropertiesDidChangeNotification = @"ACProjectPropertiesDidChangeNotification";

// Internal use only, used by the ACState controller to broadcast commands to all proxies
static NSString * const ACProjectProxyRenameCommand = @"ACProjectProxyRenameCommand";
static NSString * const ACProjectProxyDeleteCommand = @"ACProjectProxyDeleteCommand";

@interface ACState ()

/// The projects list
@property (nonatomic, strong) NSMutableArray *projects;

/// The currently active project
@property (nonatomic, strong) ACStateProject *activeProject;

/// Scans the application document directory for new projects
- (void)scanForProjects;

/// Renames a project
- (void)setName:(NSString *)newName forProjectWithName:(NSString *)oldName;
- (void)setName:(NSString *)name forProjectAtIndex:(NSUInteger)index;

/// Returns the index of a project in the projects list
- (NSUInteger)indexOfProjectWithName:(NSString *)name;

/// Returns the name of a project in the projects list
- (NSString *)nameOfProjectAtIndex:(NSUInteger)index;

/// Sets the index of a project in the projects list
/// The project is inserted at the set index, other projects are shuffled
- (void)setIndex:(NSUInteger)index forProjectWithName:(NSString *)name;
- (void)setIndex:(NSUInteger)newIndex forProjectAtIndex:(NSUInteger)oldIndex;

/// Returns the color of a project
- (UIColor *)colorForProjectWithName:(NSString *)name;
- (UIColor *)colorForProjectAtIndex:(NSUInteger)index;

/// Sets the color of a project
- (void)setColor:(UIColor *)color forProjectWithName:(NSString *)name;
- (void)setColor:(UIColor *)color forProjectAtIndex:(NSUInteger)index;

/// Activate a project
/// If nil, deactivates all projects
- (void)activateProject:(NSString *)projectName;

/// Delete a project
- (void)deleteProjectAtIndex:(NSUInteger)index;

@end

@interface ACStateProject ()

+ (ACStateProject *)projectProxyForProjectWithName:(NSString *)name;

- (void)handleProjectProxyRenameCommand:(NSNotification *)notification;
- (void)handleProjectProxyDeleteCommand:(NSNotification *)notification;
- (void)handleProjectWillRenameNotification:(NSNotification *)notification;
- (void)handleProjectDidRenameNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification;

@end

@interface ACStateCurrentProjectProxy : ACStateProject
+ (ACStateCurrentProjectProxy *)sharedProxy;
@end

@implementation ACState

#pragma mark - Application Level

@synthesize projects = _projects;

+ (ACState *)sharedState
{
    static ACState *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedState = [[self alloc] init];
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

- (void)scanForProjects
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *projectPaths = [fileManager contentsOfDirectoryAtPath:applicationDocumentsDirectory withExtensions:[NSArray arrayWithObject:ACProjectBundleExtension] options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:NO skipDirectories:NO error:NULL];
    for (NSString *path in projectPaths)
    {
        NSString *name = [path stringByDeletingPathExtension];
        if ([self indexOfProjectWithName:name] == NSNotFound)
             [self.projects addObject:[NSDictionary dictionaryWithObjectsAndKeys:name, @"name", nil, @"color" , nil]];
    }
}


#pragma mark - Project Level

@synthesize activeProject = _activeProject;

- (NSOrderedSet *)allProjects
{
    NSMutableOrderedSet *allProjects = [NSMutableOrderedSet orderedSetWithCapacity:[self.projects count]];
    for (NSDictionary *project in self.projects)
        [allProjects addObject:[ACStateProject projectProxyForProjectWithName:[project objectForKey:@"name"]]];
    return allProjects;
}

- (ACStateProject *)currentProject
{
    return [ACStateCurrentProjectProxy sharedProxy];
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

- (void)activateProject:(NSString *)projectName
{
    ECASSERT(!projectName || [self indexOfProjectWithName:projectName] != NSNotFound);
    if (!projectName)
        self.activeProject = nil;
    else
        self.activeProject = [ACStateProject projectProxyForProjectWithName:projectName];
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

@end

#pragma mark -

@implementation ACStateProject

@synthesize name = _name;

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    [[ACState sharedState] setName:name forProjectWithName:_name];
}

- (NSUInteger)index
{
    return [[ACState sharedState] indexOfProjectWithName:self.name];
}

- (void)setIndex:(NSUInteger)index
{
    [[ACState sharedState] setIndex:index forProjectWithName:self.name];
}

- (UIColor *)color
{
    return [[ACState sharedState] colorForProjectWithName:self.name];
}

- (void)setColor:(UIColor *)color
{
    [[ACState sharedState] setColor:color forProjectWithName:self.name];
}

- (BOOL)isActive
{
    return [[ACState sharedState].activeProject.name isEqualToString:self.name];
}

- (void)setActive:(BOOL)active
{
    if (!self.name)
        return;
    if (self.active == active)
        return;
    if (active)
        [[ACState sharedState] activateProject:self.name];
    else
        [[ACState sharedState] activateProject:nil];
}

#pragma mark - Internal Methods

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectProxyRenameCommand:) name:ACProjectProxyRenameCommand object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectProxyDeleteCommand:) name:ACProjectProxyDeleteCommand object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectWillRenameNotification::) name:ACProjectWillRenameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectDidRenameNotification:) name:ACProjectDidRenameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesWillChangeNotification:) name:ACProjectPropertiesWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesDidChangeNotification:) name:ACProjectPropertiesDidChangeNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (ACStateProject *)projectProxyForProjectWithName:(NSString *)name
{
    ACStateProject *proxy = [self alloc];
    proxy = [proxy init];
    proxy->_name = name;
    return proxy;
}

#pragma mark - Notification and command handling

- (void)handleProjectProxyRenameCommand:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"oldName"] isEqualToString:self.name])
        return;
    _name = [[notification userInfo] objectForKey:@"newName"];
}

- (void)handleProjectProxyDeleteCommand:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    [self willChangeValueForKey:@"name"];
    [self willChangeValueForKey:@"index"];
    [self willChangeValueForKey:@"color"];
    [self willChangeValueForKey:@"active"];
    _name = nil;
    [self didChangeValueForKey:@"name"];
    [self didChangeValueForKey:@"index"];
    [self didChangeValueForKey:@"color"];
    [self didChangeValueForKey:@"active"];
}

- (void)handleProjectWillRenameNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"oldName"] isEqualToString:self.name])
        return;
    [self willChangeValueForKey:@"name"];
}

- (void)handleProjectDidRenameNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"newName"] isEqualToString:self.name])
        return;
    [self didChangeValueForKey:@"name"];
}

- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self willChangeValueForKey:key];
}

- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"name"] isEqualToString:self.name])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self didChangeValueForKey:key];
}

@end

@implementation ACStateCurrentProjectProxy

- (NSString *)name
{
    return [ACState sharedState].activeProject.name;
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [[ACState sharedState] addObserver:self forKeyPath:@"activeProject" options:NSKeyValueObservingOptionPrior | NSKeyValueObservingOptionInitial context:NULL];
    return self;
}

- (void)dealloc
{
    [[ACState sharedState] removeObserver:self forKeyPath:@"activeProject"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if (![keyPath isEqualToString:@"activeProject"])
        return;
    if ([[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue])
    {
        [self willChangeValueForKey:@"name"];
        [self willChangeValueForKey:@"index"];
        [self willChangeValueForKey:@"color"];
        [self willChangeValueForKey:@"active"];
    }
    else
    {
        [self didChangeValueForKey:@"name"];
        [self didChangeValueForKey:@"index"];
        [self didChangeValueForKey:@"color"];
        [self didChangeValueForKey:@"active"];
    }
}

+ (ACStateCurrentProjectProxy *)sharedProxy
{
    static ACStateCurrentProjectProxy *sharedProxy = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProxy = [[self alloc] init];
    });
    return sharedProxy;
}

@end
