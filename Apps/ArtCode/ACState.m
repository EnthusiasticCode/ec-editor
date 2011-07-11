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
static NSString * const ACProjectWillMoveNotification = @"ACProjectWillMoveNotification";
static NSString * const ACProjectDidMoveNotification = @"ACProjectDidMoveNotification";
static NSString * const ACProjectPropertiesWillChangeNotification = @"ACProjectPropertiesWillChangeNotification";
static NSString * const ACProjectPropertiesDidChangeNotification = @"ACProjectPropertiesDidChangeNotification";


@interface ACState ()
+ (void)scanForProjects;
@end

@interface ACStateProject ()
- (void)handleProjectWillMoveNotification:(NSNotification *)notification;
- (void)handleProjectDidMoveNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification;
- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification;
+ (ACStateProject *)projectProxyForProjectAtPath:(NSString *)fullPath;
@end

@implementation ACState

@synthesize projects = _projects;

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
    for (NSString *path in projectPaths) {
        [projects addObject:[NSDictionary dictionaryWithObjectsAndKeys:path, @"path", [NSKeyedArchiver archivedDataWithRootObject:[UIColor redColor]], @"color" , nil]];
    }
    [defaults setObject:projects forKey:@"projects"];
    [defaults synchronize];
}

@end

@implementation ACStateProject

@synthesize fullPath = _fullPath;

- (NSString *)fullPath
{
    if (_fullPath && [[ACState sharedState] projectExistsAtPath:_fullPath])
        return [_fullPath copy];
    return nil;
}

- (void)setFullPath:(NSString *)fullPath
{
    ECASSERT(fullPath);
    ECASSERT([[fullPath pathExtension] isEqualToString:ACProjectBundleExtension]);
    [[ACState sharedState] moveProjectAtPath:_fullPath toPath:fullPath];
}

- (NSString *)path
{
    if (_fullPath && [[ACState sharedState] projectExistsAtPath:_fullPath])
        return [_fullPath stringByDeletingLastPathComponent];
    return nil;
}

- (void)setPath:(NSString *)path
{
    ECASSERT(path);
    [[ACState sharedState] moveProjectAtPath:_fullPath toPath:[path stringByAppendingPathComponent:[_fullPath lastPathComponent]]];
}

- (NSString *)fullName
{
    if (_fullPath && [[ACState sharedState] projectExistsAtPath:_fullPath])
        return [_fullPath lastPathComponent];
    return nil;
}

- (void)setFullName:(NSString *)fullName
{
    ECASSERT(fullName);
    ECASSERT([[fullName pathExtension] isEqualToString:ACProjectBundleExtension]);
    [[ACState sharedState] moveProjectAtPath:_fullPath toPath:[[_fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:fullName]];
}

- (NSString *)name
{
    if (_fullPath && [[ACState sharedState] projectExistsAtPath:_fullPath])
        return [[_fullPath lastPathComponent] stringByDeletingPathExtension];
    return nil;
}

- (void)setName:(NSString *)name
{
    ECASSERT(name);
    [[ACState sharedState] moveProjectAtPath:_fullPath toPath:[[[_fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] stringByAppendingPathExtension:[_fullPath pathExtension]]];
}

- (UIColor *)color
{
    if (_fullPath && [[ACState sharedState] projectExistsAtPath:_fullPath])
        return [[ACState sharedState] colorForProjectAtPath:_fullPath];
    return nil;
}

- (void)setColor:(UIColor *)color
{
    [[ACState sharedState] setColor:color forProjectAtPath:_fullPath];
}

- (id)init
{
    self = [super init];
    if (!self)
        return nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectWillMoveNotification:) name:ACProjectWillMoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectDidMoveNotification:) name:ACProjectDidMoveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesWillChangeNotification:) name:ACProjectPropertiesWillChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProjectPropertiesDidChangeNotification:) name:ACProjectPropertiesDidChangeNotification object:nil];
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleProjectWillMoveNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"source"] isEqualToString:_fullPath])
        return;
    [self willChangeValueForKey:@"fullPath"];
    [self willChangeValueForKey:@"path"];
    [self willChangeValueForKey:@"fullName"];
    [self willChangeValueForKey:@"name"];
    _fullPath = [[notification userInfo] objectForKey:@"destination"];
}

- (void)handleProjectDidMoveNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"destination"] isEqualToString:_fullPath])
        return;
    [self didChangeValueForKey:@"fullPath"];
    [self didChangeValueForKey:@"path"];
    [self didChangeValueForKey:@"fullName"];
    [self didChangeValueForKey:@"name"];
}

- (void)handleProjectPropertiesWillChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"projectBundlePath"] isEqualToString:_fullPath])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self willChangeValueForKey:key];
}

- (void)handleProjectPropertiesDidChangeNotification:(NSNotification *)notification
{
    if (![[[notification userInfo] objectForKey:@"projectBundlePath"] isEqualToString:_fullPath])
        return;
    for (NSString *key in [[notification userInfo] objectForKey:@"propertyKeys"])
        [self didChangeValueForKey:key];
}

+ (ACStateProject *)projectProxyForProjectAtPath:(NSString *)fullPath
{
    ACStateProject *proxy = [self alloc];
    proxy = [proxy init];
    proxy->_fullPath = fullPath;
    return proxy;
}

@end

