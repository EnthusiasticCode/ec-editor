//
//  ACStateProject.m
//  ArtCode
//
//  Created by Uri Baghin on 7/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ACStateInternal.h"

@interface ACStateProject ()

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

+ (ACStateProject *)currentProject
{
    return [ACStateCurrentProjectProxy sharedProxy];
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
