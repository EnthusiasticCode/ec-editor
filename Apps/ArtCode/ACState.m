//
//  ACState.m
//  ACState
//
//  Created by Uri Baghin on 7/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACState.h"
#import "NSFileManager(ECAdditions).h"

#pragma mark - ACState Constants
NSString * const ACProjectBundleExtension = @"acproj";

#pragma mark - ACState Notifications
NSString * const ACProjectWillRenameNotification = @"ACProjectWillRenameNotification";
NSString * const ACProjectDidRenameNotification = @"ACProjectDidRenameNotification";
NSString * const ACProjectPropertiesWillChangeNotification = @"ACProjectPropertiesWillChangeNotification";
NSString * const ACProjectPropertiesDidChangeNotification = @"ACProjectPropertiesDidChangeNotification";

#pragma mark - ACState Commands
// Internal use only, used by the ACState controller to broadcast commands to all proxies
static NSString * const ACProjectProxyRenameCommand = @"ACProjectProxyRenameCommand";

@interface ACState ()
#pragma mark - Internal Methods
+ (void)scanForProjects;
@end

@interface ACStateProject ()
#pragma mark - Internal Methods
+ (ACStateProject *)projectProxyForProjectWithName:(NSString *)name;
#pragma mark - Notification and command handling
- (void)handleProjectProxyRenameCommand:(NSNotification *)notification;
- (void)handleProjectWillRenameNotification:(NSNotification *)notification;
- (void)handleProjectDidRenameNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification;
@end

@implementation ACState

#pragma mark - Internal Methods
+ (void)initialize
{
    [self scanForProjects];
}

+ (void)scanForProjects
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *applicationDocumentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSArray *projectPaths = [fileManager subpathsOfDirectoryAtPath:applicationDocumentsDirectory withExtensions:[NSArray arrayWithObject:ACProjectBundleExtension] options:NSDirectoryEnumerationSkipsHiddenFiles skipFiles:NO skipDirectories:NO error:NULL];
    NSMutableArray *projects = [NSMutableArray array];
    for (NSString *path in projectPaths)
        [projects addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSKeyedArchiver archivedDataWithRootObject:[UIColor redColor]], @"color" , nil]];
    [defaults setObject:projects forKey:@"projects"];
    [defaults synchronize];
}

#pragma mark - Application Level
+ (ACState *)sharedState
{
    static ACState *sharedState = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedState = [[self alloc] init];
    });
    return sharedState;
}

#pragma mark - Project Level
- (NSOrderedSet *)projects
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableOrderedSet *projects = [[NSMutableOrderedSet alloc] init];
    for (NSDictionary *dictionary in [defaults arrayForKey:@"projects"])
    {
        ACStateProject *project = [ACStateProject projectProxyForProjectWithName:[dictionary objectForKey:@"name"]];
        [projects addObject:project];
    }
    return projects;
}

@end

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

#pragma mark - Internal Methods
- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectProxyRenameCommand:) name:ACProjectProxyRenameCommand object:nil];
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

